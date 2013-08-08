module StarScope::Lang
  module Go
    def self.match_file(name)
      name =~ /.*\.go$/
    end

    def self.extract(file)
      str = File.readlines(file).each_with_index do |line, line_no|
        line.scan(/^func (\w+)/) do |name|
          p "matched func #{name} on line #{line_no}"
        end
        line.scan(/^func \(\w+ \*?(\w+)\) (\w+)/) do |boundType, name|
          p "matched func #{boundType}::#{name} on line #{line_no}"
        end
        line.scan(/^package (\w+)/) do |name|
          p "matched package #{name} on line #{line_no}"
        end
        line.scan(/^type (\w+) (\w+)/) do |newName, oldName|
          p "matched type #{newName}  #{oldName} on line #{line_no}"
        end
      end
    end
  end
end
