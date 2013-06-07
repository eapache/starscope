require 'starscope/langs/ruby'
require "starscope/datum"

LANGS = [StarScope::Lang::Ruby]

class StarScope::DB

  def initialize(dirs)
    @dirs = dirs
    @files = {}
    @tables = {}

    @dirs.each do |dir|
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

  def dump
    @tables.each do |name, tbl|
      puts "== Table: #{name} =="
      tbl.each do |val, data|
        puts "#{val}"
        data.each do |datum|
          print "\t"
          puts datum
        end
      end
    end
  end

  def query(table, value)
    puts @tables[table][value]
  end

  private

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
