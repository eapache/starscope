require "starscope/parser"
require "parser/current"

module StarScope::Parsers
  class Ruby < StarScope::Parser
    def self.parse(file)
      return unless file =~ /.*\.rb/
      contents = IO.read(file)
      puts file
      p Parser::CurrentRuby.parse(contents)
    end
  end
end
