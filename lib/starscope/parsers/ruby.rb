require "starscope/parser"
require "parser/current"

module StarScope::Parsers
  class Ruby < StarScope::Parser
    def parse(file)
      return unless file =~ /.*\.rb/
      puts "Parsing #{file}..."
      ast = Parser::CurrentRuby.parse_file(file)
    end
  end
end
