module StarScope::Lang
  module Go
    def self.match_file(name)
      name =~ /.*\.go$/
    end

    def self.extract(file)
      str = File.read(file)
      str.scan(/^func (\w+)/) do |match|
        p match
      end
    end
  end
end
