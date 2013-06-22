require 'starscope/langs/ruby'
require "starscope/datum"
require 'zlib'

LANGS = [StarScope::Lang::Ruby]

class StarScope::DB

  DB_FORMAT = 2

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
          @dirs   = load_part(file)
          @files  = load_part(file)
          @tables = load_part(file)
        elsif format < DB_FORMAT
          # Old format, so read the directories segment then rebuild
          add_dirs(load_part(file))
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
        save_part(file, @dirs)
        save_part(file, @files)
        save_part(file, @tables)
      end
    end
  end

  def add_dirs(dirs)
    @dirs += dirs
    dirs.each do |dir|
      Dir["#{dir}/**/*"].each do |file|
        add_file(file)
      end
    end
  end

  def update
    @files.keys.each {|f| update_file(f)}
    cur_files = @dirs.each {|d| Dir["#{d}/**/*"]}.flatten
    (cur_files - @files.keys).each {|f| add_file(f)}
  end

  def dump_table(table)
    raise NoTableError if not @tables[table]
    puts "== Table: #{table} =="
    @tables[table].each do |val, data|
      puts "#{val}"
      data.each do |datum|
        print "\t"
        puts datum
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
    results = @tables[table][fqn[-1].to_sym]
    return [] if results.nil? || results.empty?
    results.sort! {|a,b| b.score_match(fqn) <=> a.score_match(fqn)}
    best_score = results[0].score_match(fqn)
    results.select {|result| best_score - result.score_match(fqn) < 4}
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
      defs = (@tables[:def] || []).sort {|a,b| a <=> b}
      defs.each do |key, val|
        val.each do |entry|
          file.puts entry.ctag_line
        end
      end
    end
  end

  private

  def load_part(file)
    len = file.gets.to_i
    Marshal::load(file.read(len))
  end

  def save_part(file, val)
    dat = Marshal.dump(val)
    file.puts dat.length
    file.write dat
  end

  def add_file(file)
    return if not File.file? file

    @files[file] = File.mtime(file)

    LANGS.each do |lang|
      next if not lang.match_file file
      lang.extract file do |tblname, fqn, lineno|
        datum = StarScope::Datum.new(fqn, file, lineno)
        @tables[tblname] ||= {}
        @tables[tblname][datum.key] ||= []
        @tables[tblname][datum.key] << datum
      end
    end
  end

  def remove_file(file)
    @files.delete(file)
    @tables.each do |name, tbl|
      tbl.each do |key, val|
        val.delete_if {|dat| dat.file == file}
      end
    end
  end

  def update_file(file)
    if not File.exists?(file)
      remove_file(file)
    elsif @files[file] < File.mtime(file)
      remove_file(file)
      add_file(file)
    end
  end

end
