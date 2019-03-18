require 'parser/current'

module Starscope
  module Lang
    module Ruby
      # This class exists solely to workaround/suppress issues from upstream's handling of invalid unicode.
      # See https://github.com/whitequark/parser/issues/283; workaround borrowed from
      # https://github.com/bbatsov/rubocop/commit/5e820eb5cfddf5e0f7efd2c0fa99e6b8a4c7b7e0
      class Builder < Parser::Builders::Default
        def string_value(token)
          value(token)
        end
      end

      VERSION = 2

      def self.match_file(name)
        return true if name.end_with?('.rb', '.rake')
        File.open(name) do |f|
          head = f.read(2)
          return false if head.nil? || !head.start_with?('#!')
          return f.readline.include?('ruby')
        end
      end

      def self.extract(path, contents, &block)
        buffer = Parser::Source::Buffer.new(path, 1)
        buffer.source = contents.force_encoding(Encoding::UTF_8)

        parser = Parser::CurrentRuby.new(Builder.new)
        parser.diagnostics.ignore_warnings = true
        parser.diagnostics.all_errors_are_fatal = false

        ast = parser.parse(buffer)
        extract_tree(ast, [], &block) unless ast.nil?
      end

      def self.extract_tree(tree, scope, &block)
        extract_node(tree, scope, &block)

        new_scope = []
        if [:class, :module].include? tree.type
          new_scope = scoped_name(tree.children[0], scope)
          scope += new_scope
        end

        tree.children.each { |node| extract_tree(node, scope, &block) if node.is_a? AST::Node }

        scope.pop(new_scope.count)
      end

      def self.extract_node(node, scope)
        loc = node.location

        case node.type
        when :send
          name = scoped_name(node, scope)
          yield :calls, name, line_no: loc.line, col: loc.column

          if name.last =~ /\w+=$/
            name[-1] = name.last.to_s.chop.to_sym
            yield :assigns, name, line_no: loc.line, col: loc.column
          elsif node.children[0].nil? && node.children[1] == :require && node.children[2].type == :str
            yield :requires, node.children[2].children[0].split('/'),
              line_no: loc.line, col: loc.column
          end

        when :def
          yield :defs, scope + [node.children[0]],
            line_no: loc.line, type: :func, col: loc.name.column
          yield :end, :end, line_no: loc.end.line, type: :func, col: loc.end.column

        when :defs
          yield :defs, scope + [node.children[1]],
            line_no: loc.line, type: :func, col: loc.name.column
          yield :end, :end, line_no: loc.end.line, type: :func, col: loc.end.column

        when :module, :class
          yield :defs, scope + scoped_name(node.children[0], scope),
            line_no: loc.line, type: node.type, col: loc.name.column
          yield :end, :end, line_no: loc.end.line, type: node.type, col: loc.end.column

        when :casgn
          name = scoped_name(node, scope)
          yield :assigns, name, line_no: loc.line, col: loc.name.column
          yield :defs, name, line_no: loc.line, col: loc.name.column

        when :lvasgn, :ivasgn, :cvasgn, :gvasgn
          yield :assigns, scope + [node.children[0]], line_no: loc.line, col: loc.name.column

        when :const
          name = scoped_name(node, scope)
          # handle `__ENCODING__` and other weird quasi-constants
          column = case loc
                   when Parser::Source::Map::Constant
                     loc.name.column
                   when Parser::Source::Map
                     loc.column
                   when nil
                     return
                   end
          yield :reads, name, line_no: loc.line, col: column

        when :lvar, :ivar, :cvar, :gvar
          yield :reads, scope + [node.children[0]], line_no: loc.line, col: loc.name.column

        when :sym
          # handle `:foo` vs `foo: 1`
          col = if loc.begin
                  loc.begin.column + 1
                else
                  loc.expression.column
                end
          yield :sym, [node.children[0]], line_no: loc.line, col: col
        end
      end

      def self.scoped_name(node, scope)
        if node.type == :block
          scoped_name(node.children[0], scope)
        elsif [:lvar, :ivar, :cvar, :gvar, :const, :send, :casgn].include? node.type
          if node.children[0].is_a? Symbol
            [node.children[0]]
          elsif node.children[0].is_a? AST::Node
            scoped_name(node.children[0], scope) << node.children[1]
          elsif node.children[0].nil?
            if node.type == :const
              [node.children[1]]
            else
              scope + [node.children[1]]
            end
          end
        else
          [node.type]
        end
      end
    end
  end
end
