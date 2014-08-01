require 'date'
require 'oj'
require 'set'
require 'zlib'

require 'starscope/export'
require 'starscope/matcher'
require 'starscope/output'
require 'starscope/record'

# cscope has this funky issue where it refuses to recognize function calls that
# happen outside of a function definition - this isn't an issue in C, where all
# calls must occur in a function, but in ruby et al. it is perfectly legal to
# write normal code outside the "scope" of a function definition - we insert a
# fake shim "global" function everywhere we can to work around this
CSCOPE_GLOBAL_HACK_START = "\n\t$-\n"
CSCOPE_GLOBAL_HACK_STOP = "\n\t}\n"

# dynamically load all our language extractors
LANGS = []
Dir.glob("#{File.dirname(__FILE__)}/langs/*.rb").each do |path|
  require path
  lang = /(\w+)\.rb$/.match(path)[1]
  LANGS << eval("StarScope::Lang::#{lang.capitalize}")
end

class StarScope::DB

  include StarScope::Export

  DB_FORMAT = 5

  class NoTableError < StandardError; end
  class UnknownDBFormatError < StandardError; end

  def initialize(output)
    @output = output
    @meta = {:paths => [], :files => {}, :excludes => [],
             :version => StarScope::VERSION}
    @tables = {}
  end

  # returns true if the database had to be up-converted from an old format
  def load(file)
    @output.log("Reading database from `#{file}`... ")
    File.open(file, 'r') do |file|
      Zlib::GzipReader.wrap(file) do |file|
        case file.gets.to_i
        when DB_FORMAT
          @meta   = Oj.load(file.gets)
          @tables = Oj.load(file.gets)
          return false
        when 3..4
          # Old format, so read the directories segment then rebuild
          add_paths(Oj.load(file.gets))
          return true
        when 0..2
          # Old format (pre-json), so read the directories segment then rebuild
          len = file.gets.to_i
          add_paths(Marshal::load(file.read(len)))
          return true
        else
          raise UnknownDBFormatError
        end
      end
    end
  end

  def save(file)
    @output.log("Writing database to `#{file}`...")

    # regardless of what the old version was, the new version is written by us
    @meta[:version] = StarScope::VERSION

    File.open(file, 'w') do |file|
      Zlib::GzipWriter.wrap(file) do |file|
        file.puts DB_FORMAT
        file.puts Oj.dump @meta
        file.puts Oj.dump @tables
      end
    end
  end

  def add_excludes(paths)
    @output.log("Excluding files in paths #{paths}...")
    @meta[:paths] -= paths.map {|p| normalize_glob(p)}
    paths = paths.map {|p| normalize_fnmatch(p)}
    @meta[:excludes] += paths
    @meta[:excludes].uniq!

    excluded = @meta[:files].keys.select {|name| matches_exclude?(paths, name)}
    remove_files(excluded)
  end

  def add_paths(paths)
    @output.log("Adding files in paths #{paths}...")
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
      @output.print("No changes detected.")
      return false
    end

    @output.new_pbar("Updating", changes[:modified].length + new_files.length)
    remove_files(changes[:deleted])
    update_files(changes[:modified])
    add_new_files(new_files)
    @output.finish_pbar

    true
  end

  def dump_table(table)
    raise NoTableError if not @tables[table]

    puts "== Table: #{table} =="
    puts "No records" if @tables[table].empty?

    @tables[table].sort {|a,b|
      a[:name][-1].to_s.downcase <=> b[:name][-1].to_s.downcase
    }.each do |record|
      puts StarScope::Record.format(record)
    end
  end

  def dump_meta(key)
    if key == :meta
      puts "== Metadata Summary =="
      @meta.each do |k, v|
        print "#{k}: "
        if [Array, Hash].include? v.class
          puts v.count
        else
          puts v
        end
      end
      return
    end
    raise NoTableError if not @meta[key]
    puts "== Metadata: #{key} =="
    if @meta[key].is_a? Array
      @meta[key].sort.each {|x| puts x}
    elsif @meta[key].is_a? Hash
      @meta[key].sort.each {|k,v| puts "#{k}: #{v}"}
    else
      puts @meta[key]
    end
  end

  def dump_all
    @tables.keys.each {|tbl| dump_table(tbl)}
  end

  def summary
    ret = {}

    @tables.each_key do |key|
      ret[key] = @tables[key].count
    end

    ret
  end

  def query(table, value)
    raise NoTableError if not @tables[table]
    input = @tables[table]
    StarScope::Matcher.new(value, input).query()
  end

  private

  def add_new_files(files)
    files.each do |file|
      @output.log("Adding `#{file}`")
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
      @output.log("Removing `#{file}`")
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

    LANGS.each do |lang|
      next if not lang.match_file file
      lang.extract file do |tbl, name, args|
        @tables[tbl] ||= []
        @tables[tbl] << StarScope::Record.build(file, name, args)
      end
      @meta[:files][file][:lang] = lang.name.split('::').last.to_sym
      return
    end
  end

  def file_changed(name)
    if not File.exists?(name) or not File.file?(name)
      :deleted
    elsif @meta[:files][name][:last_updated] < File.mtime(name).to_i
      :modified
    else
      :unchanged
    end
  end

end
