require 'date'
require 'oj'
require 'zlib'

require 'starscope/matcher'
require 'starscope/output'
require 'starscope/record'

require 'starscope/langs/coffeescript'
require 'starscope/langs/go'
require 'starscope/langs/lua'
require 'starscope/langs/ruby'

LANGS = [
  StarScope::Lang::CoffeeScript,
  StarScope::Lang::Go,
  StarScope::Lang::Lua,
  StarScope::Lang::Ruby
]

class StarScope::DB

  DB_FORMAT = 5

  class NoTableError < StandardError; end
  class UnknownDBFormatError < StandardError; end

  def initialize(progress, verbose)
    @output = StarScope::Output.new(progress, verbose)
    @meta = {:paths => [], :files => {}, :excludes => []}
    @tables = {}
  end

  # returns true if the database had to be up-converted from an old format
  def load(file)
    @output.log("Reading database from `#{file}`... ")
    File.open(file, 'r') do |file|
      Zlib::GzipReader.wrap(file) do |file|
        format = file.gets.to_i
        if format == DB_FORMAT
          @meta   = Oj.load(file.gets)
          @tables = Oj.load(file.gets)
          return false
        elsif format <= 2
          # Old format (pre-json), so read the directories segment then rebuild
          len = file.gets.to_i
          add_paths(Marshal::load(file.read(len)))
          return true
        elsif format <= 4
          # Old format, so read the directories segment then rebuild
          add_paths(Oj.load(file.gets))
          return true
        else
          raise UnknownDBFormatError
        end
      end
    end
  end

  def save(file)
    @output.log("Writing database to `#{file}`...")
    File.open(file, 'w') do |file|
      Zlib::GzipWriter.wrap(file) do |file|
        file.puts DB_FORMAT
        file.puts Oj.dump @meta
        file.puts Oj.dump @tables
      end
    end
  end

  def add_excludes(paths)
    @meta[:paths] -= paths.map {|p| normalize_glob(p)}
    paths = paths.map {|p| normalize_fnmatch(p)}
    @meta[:excludes] += paths
    @meta[:excludes].uniq!
    @meta[:files].delete_if do |name, record|
      if matches_exclude(paths, name)
        remove_file(name)
        true
      else
        false
      end
    end
  end

  def add_paths(paths)
    @meta[:excludes] -= paths.map {|p| normalize_fnmatch(p)}
    paths = paths.map {|p| normalize_glob(p)}
    @meta[:paths] += paths
    @meta[:paths].uniq!
    files = Dir.glob(paths).select {|f| File.file? f}
    files.delete_if {|f| matches_exclude(@meta[:excludes], f)}
    return if files.empty?
    @output.new_pbar("Building", files.length)
    add_new_files(files)
    @output.finish_pbar
  end

  def update
    new_files = (Dir.glob(@meta[:paths]).select {|f| File.file? f}) - @meta[:files].keys
    new_files.delete_if {|f| matches_exclude(@meta[:excludes], f)}
    @output.new_pbar("Updating", new_files.length + @meta[:files].length)
    changed = false
    @meta[:files].delete_if do |name, record|
      @output.log("Updating `#{name}`")
      ret = update_file(name)
      @output.inc_pbar
      changed = true if ret == :update
      ret == :delete
    end
    add_new_files(new_files)
    @output.finish_pbar
    changed || !new_files.empty?
  end

  def dump_table(table)
    raise NoTableError if not @tables[table]
    puts "== Table: #{table} =="
    @tables[table].sort {|a,b|
      a[:name][-1].downcase <=> b[:name][-1].downcase
    }.each do |record|
      puts StarScope::Record.format(record)
    end
  end

  def dump_meta(key)
    if key == :meta
      puts "== Metadata Summary =="
      @meta.each do |k, v|
        puts "#{k}: #{v.count}"
      end
      return
    end
    raise NoTableError if not @meta[key]
    puts "== Metadata: #{key} =="
    if @meta[key].is_a? Array
      @meta[key].sort.each {|x| puts x}
    else
      @meta[key].sort.each {|k,v| puts "#{k}: #{v}"}
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

  def export_ctags(filename)
    File.open(filename, 'w') do |file|
      file.puts <<END
!_TAG_FILE_FORMAT	2	/extended format/
!_TAG_FILE_SORTED	1	/0=unsorted, 1=sorted, 2=foldcase/
!_TAG_PROGRAM_AUTHOR	Evan Huus /eapache@gmail.com/
!_TAG_PROGRAM_NAME	StarScope //
!_TAG_PROGRAM_URL	https://github.com/eapache/starscope //
!_TAG_PROGRAM_VERSION	#{StarScope::VERSION}	//
END
      defs = (@tables[:defs] || {}).sort_by {|x| x[:name][-1].to_s}
      defs.each do |record|
        file.puts StarScope::Record.ctag_line(record)
      end
    end
  end

  # ftp://ftp.eeng.dcu.ie/pub/ee454/cygwin/usr/share/doc/mlcscope-14.1.8/html/cscope.html
  def export_cscope(filename)
    buf = ""
    files = []
    db_by_line().each do |file, lines|
      if not lines.empty?
        buf << "\t@#{file}\n\n"
        files << file
      end
      lines.sort.each do |line_no, records|
        line = records.first[:line].strip.gsub(/\s+/, ' ')
        toks = {}

        records.each do |record|
          index = line.index(record[:name][-1].to_s)
          while index
            toks[index] = record
            index = line.index(record[:name][-1].to_s, index + 1)
          end
        end

        next if toks.empty?

        prev = 0
        buf << line_no.to_s << " "
        toks.sort().each do |offset, record|
          buf << line.slice(prev...offset) << "\n"
          buf << StarScope::Record.cscope_mark(record[:tbl], record)
          buf << record[:name][-1].to_s << "\n"
          prev = offset + record[:name][-1].to_s.length
        end
        buf << line.slice(prev..-1) << "\n\n"
      end
    end

    buf << "\t@\n"

    header = "cscope 15 #{Dir.pwd} -c "
    offset = "%010d\n" % (header.length + 11 + buf.length)

    File.open(filename, 'w') do |file|
      file.print(header)
      file.print(offset)
      file.print(buf)

      file.print("#{@meta[:paths].length}\n")
      @meta[:paths].each {|p| file.print("#{p}\n")}
      file.print("0\n")
      file.print("#{files.length}\n")
      buf = ""
      files.each {|f| buf << f + "\n"}
      file.print("#{buf.length}\n#{buf}")
    end
  end

  private

  def add_new_files(files)
    files.each do |file|
      @output.log("Adding `#{file}`")
      @meta[:files][file] = {}
      parse_file(file)
      @output.inc_pbar
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

  def db_by_line()
    db = {}
    @tables.each do |tbl, records|
      records.each do |record|
        next if not record[:line_no]
        record[:tbl] = tbl
        db[record[:file]] ||= {}
        db[record[:file]][record[:line_no]] ||= []
        db[record[:file]][record[:line_no]] << record
      end
    end
    return db
  end

  def matches_exclude(patterns, file)
    patterns.map {|p| File.fnmatch(p, file)}.any?
  end

  def parse_file(file)
    @meta[:files][file][:last_updated] = File.mtime(file).to_i

    LANGS.each do |lang|
      next if not lang.match_file file
      lang.extract file do |tbl, name, args|
        @tables[tbl] ||= []
        @tables[tbl] << StarScope::Record.build(file, name, args)
      end
      @meta[:files][file][:lang] = lang.name.split('::').last.to_sym
    end
  end

  def remove_file(file)
    @tables.each do |name, tbl|
      tbl.delete_if {|val| val[:file] == file}
    end
  end

  def update_file(file)
    if not File.exists?(file) or not File.file?(file)
      remove_file(file)
      :delete
    elsif @meta[:files][file][:last_updated] < File.mtime(file).to_i
      remove_file(file)
      parse_file(file)
      :update
    end
  end

end
