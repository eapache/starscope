require "starscope/parser"
require "parser/current"

module StarScope::Parsers
  class Ruby < StarScope::Parser
    def parse(file)
      return unless file =~ /.*\.rb/
      puts "Parsing #{file}..."
      ast = Parser::CurrentRuby.parse_file(file)
      parse_tree(ast)
      exit
    end

    def parse_tree(ast)
      parse_node(ast)
      puts ast
      ast.children.each {|node| parse_tree node if node.is_a? AST::Node}
      #require "pry"
      #binding.pry
    end

    def parse_node(node)
    end
  end
end
