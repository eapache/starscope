require "starscope/parser"
require "starscope/value"
require "starscope/location"
require "parser/current"

module StarScope::Parsers
  class Ruby < StarScope::Parser
    def parse(file)
      return unless file =~ /.*\.rb/
      puts "Parsing #{file}..."
      @file = file
      ast = Parser::CurrentRuby.parse_file(file)
      parse_tree ast
    end

    def parse_tree(ast)
      parse_node ast
      ast.children.each {|node| parse_tree node if node.is_a? AST::Node}
    end

    def parse_node(node)
      if node.type == :send
        val = StarScope::Value.new("test")
        loc = StarScope::Location.new(@file, node.source_map.expression.line)
        db.add_ref(:send, val, loc)
      end
    end
  end
end
