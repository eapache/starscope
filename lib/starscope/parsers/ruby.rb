require "starscope/parser"

module StarScope::Parsers
  class Ruby < StarScope::Parser
    def self.parse(file)
      puts file
    end
  end
end
