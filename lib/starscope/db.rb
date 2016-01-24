require 'date'
require 'oj'
require 'set'
require 'zlib'

require 'starscope/exportable'
require 'starscope/fragment_extractor'
require 'starscope/queryable'
require 'starscope/output'

class Starscope::DB
  include Starscope::Exportable
  include Starscope::Queryable

  DB_FORMAT = 5
  FRAGMENT = :'!fragment'

  # dynamically load all our language extractors
  Dir.glob("#{File.dirname(__FILE__)}/langs/*.rb").each { |path| require path }

  langs = {}
  extractors = []
  Starscope::Lang.constants.each do |lang|
    extractor = Starscope::Lang.const_get(lang)
    extractors << extractor
    langs[lang.to_sym] = extractor.const_get(:VERSION)
  end
  LANGS = langs.freeze
  EXTRACTORS = extractors.freeze

  class NoTableError < StandardError; end
  class UnknownDBFormatError < StandardError; end

  def initialize(output, config = {})
    @output = output
    @meta = { paths: [], files: {}, excludes: [],
              langs: LANGS.dup, version: Starscope::VERSION }
    @tables = {}
    @config = config
  end

  # returns true iff the database was already in the most recent format
  def load(filename)
    @output.extra("Reading database from `#{filename}`... ")
    current_fmt = open_db(filename)
    fixup if current_fmt
    current_fmt
  end

  def save(filename)
    @output.extra("Writing database to `#{filename}`...")

    # regardless of what the old version was, the new version is written by us
    @meta[:version] = Starscope::VERSION

    @meta[:langs].merge!(LANGS)

    File.open(filename, 'w') do |file|
      Zlib::GzipWriter.wrap(file) do |stream|
        stream.puts DB_FORMAT
        stream.puts Oj.dump @meta
        stream.puts Oj.dump @tables
      end
    end
  end

  def add_excludes(paths)
    @output.extra("Excluding files in paths #{paths}...")
    @meta[:paths] -= paths.map { |p| self.class.normalize_glob(p) }
    paths = paths.map { |p| self.class.normalize_fnmatch(p) }
    @meta[:excludes] += paths
    @meta[:excludes].uniq!
    @all_excludes = nil # clear cache

    excluded = @meta[:files].keys.select { |name| matches_exclude?(name, paths) }
    remove_files(excluded)
  end

  def add_paths(paths)
    @output.extra("Adding files in paths #{paths}...")
    @meta[:excludes] -= paths.map { |p| self.class.normalize_fnmatch(p) }
    @all_excludes = nil # clear cache
    paths = paths.map { |p| self.class.normalize_glob(p) }
    @meta[:paths] += paths
    @meta[:paths].uniq!
    files = Dir.glob(paths).select { |f| File.file? f }
    files.delete_if { |f| matches_exclude?(f) }
    return if files.empty?
    @output.new_pbar('Building', files.length)
    add_files(files)
    @output.finish_pbar
  end

  def update
    changes = @meta[:files].keys.group_by { |name| file_changed(name) }
    changes[:modified] ||= []
    changes[:deleted] ||= []

    new_files = (Dir.glob(@meta[:paths]).select { |f| File.file? f }) - @meta[:files].keys
    new_files.delete_if { |f| matches_exclude?(f) }

    if changes[:deleted].empty? && changes[:modified].empty? && new_files.empty?
      @output.normal('No changes detected.')
      return false
    end

    @output.new_pbar('Updating', changes[:modified].length + new_files.length)
    remove_files(changes[:deleted])
    update_files(changes[:modified])
    add_files(new_files)
    @output.finish_pbar

    true
  end

  def line_for_record(rec)
    return rec[:line] if rec[:line]

    file = @meta[:files][rec[:file]]

    return file[:lines][rec[:line_no] - 1] if file[:lines]
  end

  def tables
    @tables.keys
  end

  def records(table)
    fail NoTableError unless @tables[table]

    @tables[table]
  end

  def metadata(key = nil)
    return @meta.keys if key.nil?

    fail NoTableError unless @meta[key]

    @meta[key]
  end

  def drop_all
    @meta[:files] = {}
    @tables = {}
  end

  private

  def open_db(filename)
    File.open(filename, 'r') do |file|
      begin
        Zlib::GzipReader.wrap(file) do |stream|
          parse_db(stream)
        end
      rescue Zlib::GzipFile::Error
        file.rewind
        parse_db(file)
      end
    end
  end

  # returns true iff the database is in the most recent format
  def parse_db(stream)
    case stream.gets.to_i
    when DB_FORMAT
      @meta   = Oj.load(stream.gets)
      @tables = Oj.load(stream.gets)
      return true
    when 3..4
      # Old format, so read the directories segment then rebuild
      add_paths(Oj.load(stream.gets))
      return false
    when 0..2
      # Old format (pre-json), so read the directories segment then rebuild
      len = stream.gets.to_i
      add_paths(Marshal.load(stream.read(len)))
      return false
    else
      fail UnknownDBFormatError
    end
  rescue Oj::ParseError
    stream.rewind
    raise unless stream.gets.to_i == DB_FORMAT
    # try reading as formated json, which is much slower, but it is sometimes
    # useful to be able to directly read your db
    objects = []
    Oj.load(stream) { |obj| objects << obj }
    @meta, @tables = objects
    return true
  end

  def fixup
    # misc things that were't worth bumping the format for, but which might not be written by old versions
    @meta[:langs] ||= {}
  end

  def all_excludes
    @all_excludes ||= @meta[:excludes] + (@config[:excludes] || []).map { |x| self.class.normalize_fnmatch(x) }
  end

  def matches_exclude?(file, patterns = all_excludes)
    patterns.map { |p| File.fnmatch(p, file) }.any?
  end

  def add_files(files)
    files.each do |file|
      @output.extra("Adding `#{file}`")
      parse_file(file)
      @output.inc_pbar
    end
  end

  def remove_files(files)
    files.each do |file|
      @output.extra("Removing `#{file}`")
      @meta[:files].delete(file)
    end
    files = files.to_set
    @tables.each do |_, tbl|
      tbl.delete_if { |val| files.include?(val[:file]) }
    end
  end

  def update_files(files)
    remove_files(files)
    add_files(files)
  end

  def parse_file(file)
    @meta[:files][file] = { last_updated: File.mtime(file).to_i }

    self.class.extractors.each do |extractor|
      begin
        next unless extractor.match_file file
      rescue => e
        @output.normal("#{extractor} raised \"#{e}\" while matching #{file}")
        next
      end

      line_cache = File.readlines(file)
      lines = Array.new(line_cache.length)
      @meta[:files][file][:sublangs] = []
      extract_file(extractor, file, line_cache, lines)

      break
    end
  end

  def extract_file(extractor, file, line_cache, lines)
    fragment_cache = {}

    extractor_metadata = extractor.extract(file, File.read(file)) do |tbl, name, args|
      case tbl
      when FRAGMENT
        fragment_cache[name] ||= []
        fragment_cache[name] << args
      else
        @tables[tbl] ||= []
        @tables[tbl] << self.class.normalize_record(file, name, args)

        if args[:line_no]
          line_cache ||= File.readlines(file)
          lines ||= Array.new(line_cache.length)
          lines[args[:line_no] - 1] = line_cache[args[:line_no] - 1].chomp
        end
      end
    end

    fragment_cache.each do |lang, frags|
      extract_file(Starscope::FragmentExtractor.new(lang, frags), file, line_cache, lines)
      @meta[:files][file][:sublangs] << lang
    end

    @meta[:files][file][:lang] = extractor.name.split('::').last.to_sym
    @meta[:files][file][:lines] = lines

    if extractor_metadata.is_a? Hash
      @meta[:files][file] = extractor_metadata.merge!(@meta[:files][file])
    end

  rescue => e
    @output.normal("#{extractor} raised \"#{e}\" while extracting #{file}")
  end

  def file_changed(name)
    file_meta = @meta[:files][name]
    if matches_exclude?(name) || !File.exist?(name) || !File.file?(name)
      :deleted
    elsif (file_meta[:last_updated] < File.mtime(name).to_i) ||
          language_out_of_date(file_meta[:lang]) ||
          (file_meta[:sublangs] || []).any? { |lang| language_out_of_date(lang) }
      :modified
    else
      :unchanged
    end
  end

  def language_out_of_date(lang)
    return false unless lang
    return true unless LANGS[lang]
    (@meta[:langs][lang] || 0) < LANGS[lang]
  end

  class << self
    # File.fnmatch treats a "**" to match files and directories recursively
    def normalize_fnmatch(path)
      if path == '.'
        '**'
      elsif File.directory?(path)
        File.join(path, '**')
      else
        path
      end
    end

    # Dir.glob treats a "**" to only match directories recursively; you need
    # "**/*" to match all files recursively
    def normalize_glob(path)
      if path == '.'
        File.join('**', '*')
      elsif File.directory?(path)
        File.join(path, '**', '*')
      else
        path
      end
    end

    def normalize_record(file, name, args)
      args[:file] = file
      args[:name] = Array(name).map(&:to_sym)
      args
    end

    def extractors # so we can stub it in tests
      EXTRACTORS
    end
  end
end
