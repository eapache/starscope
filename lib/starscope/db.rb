require 'starscope/langs/ruby'

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
      tbl.each do |val, maps|
        puts "#{val}"
        maps.each do |scoped_val, loc|
          puts "\t#{scoped_val.join ' '} -- #{loc}"
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
      lang.extract file do |tblname, value, location|
        @tables[tblname] ||= {}
        @tables[tblname][value[-1]] ||= {}
        @tables[tblname][value[-1]][value] = location
      end
    end
  end

  def remove_file(file)
    @files.delete(file)
    @tables.each do |name, tbl|
      tbl.keys.each do |key|
        tbl[key] = tbl[key].delete_if {|k, loc| loc.file == file}
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
