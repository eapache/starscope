require 'starscope/langs/ruby'

class StarScope::DB

  def initialize(directory)
    @directory = directory

    Dir["#{directory}/**/*"].each do |file|
      next if not File.file? file
      next if not StarScope::Lang::Ruby.match_file file
      StarScope::Lang::Ruby.extract file do |tblname, value, location|
        table[tblname] ||= {}
        table[tblname][value[-1]] ||= {}
        table[tblname][value[-1]][value] = location
      end
    end
  end

  def to_s
    ret = ""

    table.each do |name, tbl|
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

  def table
    @table ||= {}
  end

end
