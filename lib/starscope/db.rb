require 'starscope/langs/ruby'
require "starscope/datum"
require 'zlib'

LANGS = [StarScope::Lang::Ruby]

class StarScope::DB

  DB_FORMAT = 1

  def initialize
    @dirs = []
    @files = {}
    @tables = {}
  end

  def load(file)
    File.open(file, 'r') do |file|
      Zlib::GzipReader.wrap(file) do |file|
        raise "Database format not recognized" if DB_FORMAT != file.gets.to_i
        @dirs   = load_part(file)
        @files  = load_part(file)
        @tables = load_part(file)
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
    @dirs << dirs
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

  def print_summary
    @tables.each do |name, tbl|
      puts "#{name} - #{tbl.keys.count} entries"
    end
  end

  def query(table, value)
    fqn = value.split("::")
    results = @tables[table][fqn[-1].to_sym]
    results.sort! {|a,b| b.score_match(fqn) <=> a.score_match(fqn)}
    best_score = results[0].score_match(fqn)
    results.each do |result|
      # 4 is a guess at the best heuristic, not magic
      return if best_score - result.score_match(fqn) > 4
      puts result
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
