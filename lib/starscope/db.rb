require 'starscope/langs/ruby'
require 'starscope/datum'
require 'date'
require 'json'
require 'zlib'
require 'ruby-progressbar'

LANGS = [StarScope::Lang::Ruby]

class StarScope::DB

  DB_FORMAT = 3
  PBAR_FORMAT = '%t: %c/%C %E ||%b>%i||'

  class NoTableError < StandardError; end
  class UnknownDBFormatError < StandardError; end

  def initialize
    @dirs = []
    @files = {}
    @tables = {}
  end

  def load(file)
    File.open(file, 'r') do |file|
      Zlib::GzipReader.wrap(file) do |file|
        format = file.gets.to_i
        if format == DB_FORMAT
          @dirs   = JSON.parse(file.gets, symbolize_names: false)
          @files  = JSON.parse(file.gets, symbolize_names: false)
          @tables = JSON.parse(file.gets, symbolize_names: true)
        elsif format <= 2
          # Old format (pre-json), so read the directories segment then rebuild
          len = file.gets.to_i
          add_dirs(Marshal::load(file.read(len)))
        elsif format < DB_FORMAT
          # Old format, so read the directories segment then rebuild
          add_dirs(JSON.parse(file.gets, symbolize_names: false))
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
        file.puts JSON.fast_generate @dirs
        file.puts JSON.fast_generate @files
        file.puts JSON.fast_generate @tables
      end
    end
  end

  def add_dirs(dirs)
    dirs -= @dirs
    return if dirs.empty?
    @dirs += dirs
    files = dirs.map {|d| Dir["#{d}/**/*"]}.flatten
    return if files.empty?
    pbar = ProgressBar.create(:title => "Building Database", :total => files.length, :format => PBAR_FORMAT)
    files.each do |f|
      add_file(f)
      pbar.increment
    end
  end

  def update
    new_files = (@dirs.map {|d| Dir["#{d}/**/*"]}.flatten) - @files.keys
    pbar = ProgressBar.create(:title => "Updating Database", :total => new_files.length + @files.length, :format => PBAR_FORMAT)
    @files.keys.each do |f|
      update_file(f)
      pbar.increment
    end
    new_files.each do |f|
      add_file(f)
      pbar.increment
    end
  end

  def dump_table(table)
    raise NoTableError if not @tables[table]
    puts "== Table: #{table} =="
    @tables[table].each do |val, data|
      puts "#{val}"
      data.each do |datum|
        print "\t"
        puts StarScope::Datum.to_s(datum)
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
    results = @tables[table][fqn.last.to_sym]
    return [] if results.nil? || results.empty?
    results.sort! do |a,b|
      StarScope::Datum.score_match(b, fqn) <=> StarScope::Datum.score_match(a, fqn)
    end
    best_score = StarScope::Datum.score_match(results[0], fqn)
    results.select do |result|
      best_score - StarScope::Datum.score_match(result, fqn) < 4
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
      defs = (@tables[:defs] || []).sort {|a,b| a <=> b}
      defs.each do |key, val|
        val.each do |entry|
          file.puts StarScope::Datum.ctag_line(entry)
        end
      end
    end
  end

  private

  def add_file(file)
    return if not File.file? file

    @files[file] = File.mtime(file).to_s

    LANGS.each do |lang|
      next if not lang.match_file file
      lang.extract file do |tbl, key, args|
        @tables[tbl] ||= {}
        @tables[tbl][key] ||= []
        @tables[tbl][key] << StarScope::Datum.build(key, file, args)
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
    if not File.exists?(file)
      remove_file(file)
    elsif DateTime.parse(@files[file]).to_time < File.mtime(file)
      remove_file(file)
      add_file(file)
    end
  end

end
