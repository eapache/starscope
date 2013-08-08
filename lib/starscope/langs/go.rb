module StarScope::Lang
  module Go
    def self.match_file(name)
      name =~ /.*\.go$/
    end

    def self.extract(file)
      str = File.readlines(file).each_with_index do |line, line_no|
        line.scan(/^func (\w+)/) do |name|
          yield :defs, name[0], line_no: line_no+1
        end
        line.scan(/^func \(\w+ \*?(\w+)\) (\w+)/) do |boundType, name|
          yield :defs, name, line_no: line_no+1, scope: [boundType]
        end
        line.scan(/^package (\w+)/) do |name|
          yield :defs, name[0], line_no: line_no+1
        end
        line.scan(/^type (\w+) (\w+)/) do |newName, oldName|
          yield :defs, newName, line_no: line_no+1
        end
      end
    end
  end
end
