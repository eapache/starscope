require 'starscope/langs/go'
require 'starscope/langs/ruby'
require 'starscope/datum'
require 'date'
require 'oj'
require 'zlib'
require 'ruby-progressbar'

LANGS = [
  StarScope::Lang::Go,
  StarScope::Lang::Ruby
]

class StarScope::DB

  DB_FORMAT = 4
  PBAR_FORMAT = '%t: %c/%C %E ||%b>%i||'

  class NoTableError < StandardError; end
  class UnknownDBFormatError < StandardError; end

  def initialize
    @paths = []
    @files = {}
    @tables = {}
  end

  def load(file)
    File.open(file, 'r') do |file|
      Zlib::GzipReader.wrap(file) do |file|
        format = file.gets.to_i
        if format == DB_FORMAT
          @paths  = Oj.load(file.gets)
          @files  = Oj.load(file.gets)
          @tables = Oj.load(file.gets, symbol_keys: true)
        elsif format <= 2
          # Old format (pre-json), so read the directories segment then rebuild
          len = file.gets.to_i
          add_paths(Marshal::load(file.read(len)))
        elsif format < DB_FORMAT
          # Old format, so read the directories segment then rebuild
          add_paths(Oj.load(file.gets))
        elsif format > DB_FORMAT
          raise UnknownDBFormatError
        end
      end
    end
  end

  def save(file)
    File.open(file, 'w') do |file|
      Zlib::GzipWriter.wrap(file) do |file|
        file.puts DB_FORMAT
        file.puts Oj.dump @paths
        file.puts Oj.dump @files
        file.puts Oj.dump @tables
      end
    end
  end

  def add_paths(paths)
    paths -= @paths
    return if paths.empty?
    @paths += paths
    files = paths.map {|p| self.class.files_from_path(p)}.flatten
    return if files.empty?
    pbar = ProgressBar.create(title: "Building", total: files.length, format: PBAR_FORMAT, length: 80)
    files.each do |f|
      add_file(f)
      pbar.increment
    end
  end

  def update
    new_files = (@paths.map {|p| self.class.files_from_path(p)}.flatten) - @files.keys
    pbar = ProgressBar.create(title: "Updating", total: new_files.length + @files.length, format: PBAR_FORMAT, length: 80)
    changed = @files.keys.map do |f|
      changed = update_file(f)
      pbar.increment
      changed
    end
    new_files.each do |f|
      add_file(f)
      pbar.increment
    end
    changed.any? || !new_files.empty?
  end

  def dump_table(table)
    raise NoTableError if not @tables[table]
    puts "== Table: #{table} =="
    @tables[table].each do |val, data|
      puts "#{val}"
      data.each do |datum|
        print "\t"
        puts StarScope::Datum.to_s(val, datum)
      end
    end
  end

  def dump_all
    @tables.keys.each {|tbl| dump_table(tbl)}
  end

  def summary
    ret = {}

    @tables.each_key do |key|
      ret[key] = @tables[key].keys.count
    end

    ret
  end

  def query(table, value)
    fqn = value.split("::")
    raise NoTableError if not @tables[table]
    key = fqn.last.to_sym
    results = @tables[table][key]
    return [] if results.nil? || results.empty?
    results.sort! do |a,b|
      StarScope::Datum.score_match(b, fqn) <=> StarScope::Datum.score_match(a, fqn)
    end
    best_score = StarScope::Datum.score_match(results[0], fqn)
    results = results.select do |result|
      best_score - StarScope::Datum.score_match(result, fqn) < 4
    end
    return key, results
  end

  def export_ctags(filename)
    File.open(filename, 'w') do |file|
      file.puts <<END
!_TAG_FILE_FORMAT	2	//
!_TAG_FILE_SORTED	1	/0=unsorted, 1=sorted, 2=foldcase/
!_TAG_PROGRAM_AUTHOR	Evan Huus //
!_TAG_PROGRAM_NAME	Starscope //
!_TAG_PROGRAM_URL	https://github.com/eapache/starscope //
!_TAG_PROGRAM_VERSION	#{StarScope::VERSION}	//
END
      defs = (@tables[:defs] || {}).sort
      defs.each do |key, val|
        val.each do |entry|
          file.puts StarScope::Datum.ctag_line(key, entry)
        end
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
      lines.sort.each do |line_no, vals|
        line = vals.first[:entry][:line].strip.gsub(/\s+/, ' ')
        toks = {}

        vals.each do |val|
          index = line.index(val[:key].to_s)
          while index
            toks[index] = val
            index = line.index(val[:key].to_s, index + 1)
          end
        end

        next if toks.empty?

        prev = 0
        buf << line_no.to_s << " "
        toks.sort().each do |offset, val|
          buf << line.slice(prev...offset) << "\n"
          buf << StarScope::Datum.cscope_mark(val[:tbl], val[:entry])
          buf << val[:key].to_s << "\n"
          prev = offset + val[:key].to_s.length
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

      file.print("#{@paths.length}\n")
      @paths.each {|p| file.print("#{p}\n")}
      file.print("0\n")
      file.print("#{files.length}\n")
      buf = ""
      files.each {|f| buf << f + "\n"}
      file.print("#{buf.length}\n#{buf}")
    end
  end

  private

  def self.files_from_path(path)
    if File.file?(path)
      [path]
    elsif File.directory?(path)
      Dir[File.join(path, "**", "*")].select {|p| File.file?(p)}
    else
      []
    end
  end

  def db_by_line()
    tmpdb = {}
    @tables.each do |tbl, vals|
      vals.each do |key, val|
        val.each do |entry|
          if entry[:line_no]
            tmpdb[entry[:file]] ||= {}
            tmpdb[entry[:file]][entry[:line_no]] ||= []
            tmpdb[entry[:file]][entry[:line_no]] << {tbl: tbl, key: key, entry: entry}
          end
        end
      end
    end
    return tmpdb
  end

  def add_file(file)
    return if not File.file? file

    @files[file] = File.mtime(file).to_s

    LANGS.each do |lang|
      next if not lang.match_file file
      lang.extract file do |tbl, key, args|
        key = key.to_sym
        @tables[tbl] ||= {}
        @tables[tbl][key] ||= []
        @tables[tbl][key] << StarScope::Datum.build(file, args)
      end
    end
  end

  def remove_file(file)
    @files.delete(file)
    @tables.each do |name, tbl|
      tbl.each do |key, val|
        val.delete_if {|dat| dat[:file] == file}
      end
    end
  end

  def update_file(file)
    if not File.exists?(file) or not File.file?(file)
      remove_file(file)
      true
    elsif DateTime.parse(@files[file]).to_time < File.mtime(file)
      remove_file(file)
      add_file(file)
      true
    else
      false
    end
  end

end
