require 'starscope/langs/go'
require 'starscope/langs/ruby'
require 'starscope/datum'
require 'starscope/scorer'
require 'date'
require 'oj'
require 'zlib'
require 'ruby-progressbar'

LANGS = [
  StarScope::Lang::Go,
  StarScope::Lang::Ruby
]

class StarScope::DB

  DB_FORMAT = 5
  PBAR_FORMAT = '%t: %c/%C %E ||%b>%i||'

  class NoTableError < StandardError; end
  class UnknownDBFormatError < StandardError; end

  def initialize(progress)
    @progress = progress
    @meta = {:paths => [], :files => []}
    @tables = {}
  end

  def load(file)
    File.open(file, 'r') do |file|
      Zlib::GzipReader.wrap(file) do |file|
        format = file.gets.to_i
        if format == DB_FORMAT
          @meta   = Oj.load(file.gets, :symbol_keys => true)
          @tables = Oj.load(file.gets, :symbol_keys => true)
        elsif format <= 2
          # Old format (pre-json), so read the directories segment then rebuild
          len = file.gets.to_i
          add_paths(Marshal::load(file.read(len)))
        elsif format <= 4
          # Old format, so read the directories segment then rebuild
          add_paths(Oj.load(file.gets))
        else
          raise UnknownDBFormatError
        end
      end
    end
  end

  def save(file)
    File.open(file, 'w') do |file|
      Zlib::GzipWriter.wrap(file) do |file|
        file.puts DB_FORMAT
        file.puts Oj.dump @meta
        file.puts Oj.dump @tables
      end
    end
  end

  def add_paths(paths)
    paths -= @meta[:paths]
    return if paths.empty?
    @meta[:paths] += paths
    files = paths.map {|p| self.class.files_from_path(p)}.flatten
    return if files.empty?
    if @progress
      pbar = ProgressBar.create(:title => "Building", :total => files.length, :format => PBAR_FORMAT, :length => 80)
    end
    files.each do |f|
      add_file(f)
      pbar.increment if @progress
    end
  end

  def update
    new_files = (@meta[:paths].map {|p| self.class.files_from_path(p)}.flatten) - @meta[:files].map {|f| f[:name]}
    if @progress
      pbar = ProgressBar.create(:title => "Updating", :total => new_files.length + @meta[:files].length, :format => PBAR_FORMAT, :length => 80)
    end
    changed = false
    @meta[:files].delete_if do |f|
      ret = update_file(f)
      pbar.increment if @progress
      changed = true if ret == :update
      ret == :delete
    end
    new_files.each do |f|
      add_file(f)
      pbar.increment if @progress
    end
    changed || !new_files.empty?
  end

  def dump_table(table)
    raise NoTableError if not @tables[table]
    puts "== Table: #{table} =="
    @tables[table].sort_by{|x| x[:name][-1].downcase}.each do |data|
      puts StarScope::Datum.to_s(datum)
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
    results = @tables[table]
    return results if results.empty?
    scorer = StarScope::Scorer.new(value)
    results.sort_by! {|x| scorer.score(x)}
    best_score = scorer.score(results[-1])
    results.select do |result|
      best_score == scorer.score(result)
    end
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
      defs = (@tables[:defs] || {}).sort_by {|x| x[:name][-1]}
      defs.each do |val|
        file.puts StarScope::Datum.ctag_line(val)
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
          index = line.index(val[:name][-1].to_s)
          while index
            toks[index] = val
            index = line.index(val[:name][-1].to_s, index + 1)
          end
        end

        next if toks.empty?

        prev = 0
        buf << line_no.to_s << " "
        toks.sort().each do |offset, val|
          buf << line.slice(prev...offset) << "\n"
          buf << StarScope::Datum.cscope_mark(val)
          buf << val[:name].to_s << "\n"
          prev = offset + val[:name].to_s.length
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
      files.each {|f| buf << f[:name] + "\n"}
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
      vals.each do |val|
        if val[:line_no]
          tmpdb[val[:file]] ||= {}
          tmpdb[val[:file]][val[:line_no]] ||= []
          val[:tbl] = tbl
          tmpdb[val[:file]][val[:line_no]] << val
        end
      end
    end
    return tmpdb
  end

  def add_file(file)
    return if not File.file? file

    record = {:name => file}

    parse_file(record)

    @meta[:files] << record
  end

  def parse_file(file)
    file[:last_updated] = File.mtime(file[:name]).to_i

    LANGS.each do |lang|
      next if not lang.match_file file[:name]
      lang.extract file[:name] do |tbl, name, args|
        @tables[tbl] ||= []
        @tables[tbl] << StarScope::Datum.build(file[:name], name, args)
      end
      file[:lang] = lang.name.split('::').last.to_sym
    end
  end

  def remove_file(file)
    @tables.each do |name, tbl|
      tbl.delete_if {|val| val[:file] == file[:name]}
    end
  end

  def update_file(file)
    if not File.exists?(file[:name]) or not File.file?(file[:name])
      remove_file(file)
      :delete
    elsif file[:last_updated] < File.mtime(file[:name]).to_i
      remove_file(file)
      parse_file(file)
      :update
    end
  end

end
