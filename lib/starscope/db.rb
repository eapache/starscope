require 'date'
require 'oj'
require 'set'
require 'zlib'

require 'starscope/export'
require 'starscope/matcher'
require 'starscope/output'

# dynamically load all our language extractors
LANGS = {}
EXTRACTORS = []
Dir.glob("#{File.dirname(__FILE__)}/langs/*.rb").each do |path|
  require path
  lang = /(\w+)\.rb$/.match(path)[1].capitalize
  mod_name = "Starscope::Lang::#{lang}"
  EXTRACTORS << eval(mod_name)
  LANGS[lang.to_sym] = eval("#{mod_name}::VERSION")
end

class Starscope::DB

  include Starscope::Export

  DB_FORMAT = 5

  class NoTableError < StandardError; end
  class UnknownDBFormatError < StandardError; end

  def initialize(output)
    @output = output
    @meta = {:paths => [], :files => {}, :excludes => [],
             :langs => LANGS, :version => Starscope::VERSION}
    @tables = {}
  end

  # returns true if the database had to be up-converted from an old format
  def load(filename)
    @output.extra("Reading database from `#{filename}`... ")
    File.open(filename, 'r') do |file|
      Zlib::GzipReader.wrap(file) do |stream|
        case stream.gets.to_i
        when DB_FORMAT
          @meta   = Oj.load(stream.gets)
          @tables = Oj.load(stream.gets)
          @meta[:langs] ||= {}
          return false
        when 3..4
          # Old format, so read the directories segment then rebuild
          add_paths(Oj.load(stream.gets))
          return true
        when 0..2
          # Old format (pre-json), so read the directories segment then rebuild
          len = stream.gets.to_i
          add_paths(Marshal::load(stream.read(len)))
          return true
        else
          raise UnknownDBFormatError
        end
      end
    end
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
    @meta[:paths] -= paths.map {|p| normalize_glob(p)}
    paths = paths.map {|p| normalize_fnmatch(p)}
    @meta[:excludes] += paths
    @meta[:excludes].uniq!

    excluded = @meta[:files].keys.select {|name| matches_exclude?(paths, name)}
    remove_files(excluded)
  end

  def add_paths(paths)
    @output.extra("Adding files in paths #{paths}...")
    @meta[:excludes] -= paths.map {|p| normalize_fnmatch(p)}
    paths = paths.map {|p| normalize_glob(p)}
    @meta[:paths] += paths
    @meta[:paths].uniq!
    files = Dir.glob(paths).select {|f| File.file? f}
    files.delete_if {|f| matches_exclude?(@meta[:excludes], f)}
    return if files.empty?
    @output.new_pbar("Building", files.length)
    add_new_files(files)
    @output.finish_pbar
  end

  def update
    changes = @meta[:files].keys.group_by {|name| file_changed(name)}
    changes[:modified] ||= []
    changes[:deleted] ||= []

    new_files = (Dir.glob(@meta[:paths]).select {|f| File.file? f}) - @meta[:files].keys
    new_files.delete_if {|f| matches_exclude?(@meta[:excludes], f)}

    if changes[:deleted].empty? && changes[:modified].empty? && new_files.empty?
      @output.normal("No changes detected.")
      return false
    end

    @output.new_pbar("Updating", changes[:modified].length + new_files.length)
    remove_files(changes[:deleted])
    update_files(changes[:modified])
    add_new_files(new_files)
    @output.finish_pbar

    true
  end

  def tables
    @tables.keys
  end

  def records(table)
    raise NoTableError if not @tables[table]

    @tables[table]
  end

  def metadata(key=nil)
    return @meta.keys if key.nil?

    raise NoTableError unless @meta[key]

    @meta[key]
  end

  def query(table, value)
    raise NoTableError if not @tables[table]
    input = @tables[table]
    Starscope::Matcher.new(value, input).query()
  end

  def line_for_record(rec)
    return rec[:line] if rec[:line]

    file = @meta[:files][rec[:file]]

    return file[:lines][rec[:line_no]-1] if file[:lines]
  end

  private

  def add_new_files(files)
    files.each do |file|
      @output.extra("Adding `#{file}`")
      parse_file(file)
      @output.inc_pbar
    end
  end

  def update_files(files)
    remove_files(files)
    add_new_files(files)
  end

  def remove_files(files)
    files.each do |file|
      @output.extra("Removing `#{file}`")
      @meta[:files].delete(file)
    end
    files = files.to_set
    @tables.each do |name, tbl|
      tbl.delete_if {|val| files.include?(val[:file])}
    end
  end

  # File.fnmatch treats a "**" to match files and directories recursively
  def normalize_fnmatch(path)
    if path == "."
      "**"
    elsif File.directory?(path)
      File.join(path, "**")
    else
      path
    end
  end

  # Dir.glob treats a "**" to only match directories recursively; you need
  # "**/*" to match all files recursively
  def normalize_glob(path)
    if path == "."
      File.join("**", "*")
    elsif File.directory?(path)
      File.join(path, "**", "*")
    else
      path
    end
  end

  def matches_exclude?(patterns, file)
    patterns.map {|p| File.fnmatch(p, file)}.any?
  end

  def parse_file(file)
    @meta[:files][file] = {:last_updated => File.mtime(file).to_i}

    EXTRACTORS.each do |extractor|
      next if not extractor.match_file file

      lines = nil
      line_cache = nil
      extractor.extract file do |tbl, name, args|
        @tables[tbl] ||= []
        @tables[tbl] << self.class.normalize_record(file, name, args)

        if args[:line_no]
          line_cache ||= File.readlines(file)
          lines ||= Array.new(line_cache.length)
          lines[args[:line_no]-1] = line_cache[args[:line_no]-1].chomp
        end
      end

      @meta[:files][file][:lang] = extractor.name.split('::').last.to_sym
      @meta[:files][file][:lines] = lines
      return
    end
  end

  def file_changed(name)
    file_meta = @meta[:files][name]
    if !File.exists?(name) || !File.file?(name)
      :deleted
    elsif (file_meta[:last_updated] < File.mtime(name).to_i) ||
          (file_meta[:lang] && (@meta[:langs][file_meta[:lang]] || 0) < LANGS[file_meta[:lang]])
      :modified
    else
      :unchanged
    end
  end

  def self.normalize_record(file, name, args)
    args[:file] = file

    if name.is_a? Array
      args[:name] = name.map {|x| x.to_sym}
    else
      args[:name] = [name.to_sym]
    end

    args
  end

end
