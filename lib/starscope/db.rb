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

  def to_s
    ret = ""

    @tables.each do |name, tbl|
      ret += "== Table: #{name} ==\n"
      tbl.each do |val, maps|
        ret += "#{val}\n"
        maps.each do |scoped_val, loc|
          ret += "\t#{scoped_val.join ' '} -- #{loc}\n"
        end
      end
    end
    
    ret
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
    #TODO Actually remove from tables
    @files.delete(file)
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
