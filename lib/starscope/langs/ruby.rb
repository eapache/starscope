require "starscope/location"

require "parser/current"

module StarScope::Lang
  module Ruby
    def self.match_file(name)
      name =~ /.*\.rb/
    end

    def self.extract(file, &block)
      ast = Parser::CurrentRuby.parse_file(file)
      extract_tree ast, file, &block
    end

    private

    def self.extract_tree(ast, file, &block)
      extract_node ast, file, &block
      ast.children.each {|node| extract_tree node, file, &block if node.is_a? AST::Node}
    end

    def self.extract_node(node, file, &block)
      if node.type == :send
        loc = StarScope::Location.new(file, node.source_map.expression.line)
        yield :send, scoped_name(node), loc
      end
    end

    def self.scoped_name(node)
      if node.children[0].is_a? AST::Node
        scoped_name(node.children[0]) << node.children[1]
      elsif node.children[0].is_a? Symbol
        [node.children[0]]
      else
        [node.children[1]]
      end
    end
  end
end
