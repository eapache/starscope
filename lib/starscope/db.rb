require 'starscope/langs/ruby'

class StarScope::DB

  def initialize(dirs)
    langs = [StarScope::Lang::Ruby]
    dirs.each do |dir|
      Dir["#{dir}/**/*"].each do |file|
        next if not File.file? file
        langs.each do |lang|
          next if not lang.match_file file
          lang.extract file do |tblname, value, location|
            tables[tblname] ||= {}
            tables[tblname][value[-1]] ||= {}
            tables[tblname][value[-1]][value] = location
          end
        end
      end
    end
  end

  def update
    abort "not yet implemented"
  end

  def to_s
    ret = ""

    tables.each do |name, tbl|
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

  def tables
    @tables ||= {}
  end

end
