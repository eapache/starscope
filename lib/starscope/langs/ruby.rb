require "starscope/location"

require "parser/current"

module StarScope::Lang
  module Ruby
    def self.match_file(name)
      name =~ /.*\.rb/
    end

    def self.extract(file, &block)
      ast = Parser::CurrentRuby.parse_file(file)
      Extractor.new(ast, file).extract &block
    end

    private

    class Extractor
      def initialize(ast, file)
        @ast = ast
        @file = file
        @scope = []
      end
      
      def extract(&block)
        extract_tree(@ast, &block)
      end

      private

      def extract_tree(tree, &block)
        extract_node tree, &block

        scope_count = 0
        if [:class, :module].include? tree.type
          new_scope = scoped_name(tree.children[0])
          @scope << new_scope
          scope_count = new_scope.count
        end

        tree.children.each {|node| extract_tree node, &block if node.is_a? AST::Node}

        @scope.pop(scope_count)
      end

      def extract_node(node)
        if node.type == :send
          loc = StarScope::Location.new(@file, node.source_map.expression.line)
          yield :send, scoped_name(node), loc
        end
      end

      def scoped_name(node)
        if node.is_a? Symbol
          [node]
        elsif node.is_a? AST::Node
          if node.children[0].is_a? Symbol
            [node.children[0]]
          elsif node.children[0].is_a? AST::Node
            scoped_name(node.children[0]) << node.children[1]
          elsif node.children[0].nil?
            if node.type == :const
              [node.children[1]]
            else
              @scope + [node.children[1]]
            end
          end
        end
      end
    end
  end
end
