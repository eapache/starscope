require "parser/current"

module StarScope::Lang
  module Ruby
    def self.match_file(name)
      return true if name.end_with?(".rb")
      File.open(name) do |f|
        head = f.read(2)
        return false if head.nil? or not head.start_with?("#!")
        return f.readline.include?("ruby")
      end
    rescue ArgumentError # may occur if file is binary (invalid UTF)
      false
    end

    def self.extract(file, &block)
      begin
        ast = Parser::CurrentRuby.parse_file(file)
      rescue
      else
        Extractor.new(ast).extract &block
      end
    end

    private

    class Extractor
      def initialize(ast)
        @ast = ast
        @scope = []
      end

      def extract(&block)
        extract_tree(@ast, &block) if not @ast.nil?
      end

      private

      def extract_tree(tree, &block)
        extract_node tree, &block

        new_scope = []
        if [:class, :module].include? tree.type
          new_scope = scoped_name(tree.children[0])
          @scope += new_scope
        end

        tree.children.each {|node| extract_tree node, &block if node.is_a? AST::Node}

        @scope.pop(new_scope.count)
      end

      def extract_node(node)
        case node.type
        when :send
          fqn = scoped_name(node)
          yield :calls, fqn, :line_no => node.location.expression.line
          if node.children[0].nil? and node.children[1] == :require and node.children[2].type == :str
            fqn = node.children[2].children[0].split("/")
            yield :requires, fqn, :line_no => node.location.expression.line
          end
        when :def
          yield :defs, @scope + [node.children[0]],
            :line_no => node.location.expression.line, :type => :func
          yield :end, :end, :line_no => node.location.end.line, :type => :func
        when :defs
          yield :defs, @scope + [node.children[1]],
            :line_no => node.location.expression.line, :type => :func
          yield :end, :end, :line_no => node.location.end.line, :type => :func
        when :module, :class
          fqn = @scope + scoped_name(node.children[0])
          yield :defs, fqn, :line_no => node.location.expression.line, :type => node.type
          yield :end, :end, :line_no => node.location.end.line, :type => node.type
        when :casgn
          fqn = scoped_name(node)
          yield :assigns, fqn, :line_no => node.location.expression.line
          yield :defs, fqn, :line_no => node.location.expression.line
        when :lvasgn, :ivasgn, :cvasgn, :gvasgn
          yield :assigns, @scope + [node.children[0]], :line_no => node.location.expression.line
        end
      end

      def scoped_name(node)
        if node.type == :block
          scoped_name(node.children[0])
        elsif [:lvar, :ivar, :cvar, :gvar, :const, :send, :casgn].include? node.type
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
        else
          [node.type]
        end
      end
    end
  end
end
