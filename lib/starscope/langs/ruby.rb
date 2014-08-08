require "parser/current"

module Starscope::Lang
  module Ruby
    VERSION = 1

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
        extract_tree(ast, [], &block) if not ast.nil?
      end
    end

    private

    def self.extract_tree(tree, scope, &block)
      extract_node(tree, scope, &block)

      new_scope = []
      if [:class, :module].include? tree.type
        new_scope = scoped_name(tree.children[0], scope)
        scope += new_scope
      end

      tree.children.each {|node| extract_tree(node, scope, &block) if node.is_a? AST::Node}

      scope.pop(new_scope.count)
    end

    def self.extract_node(node, scope)
      loc = node.location

      case node.type
      when :send
        name = scoped_name(node, scope)
        yield :calls, name, :line_no => loc.line, :col => loc.column

        if name.last.to_s =~ /\w+=$/
          name[-1] = name.last.to_s.chop.to_sym
          yield :assigns, name, :line_no => loc.line, :col => loc.column
        elsif node.children[0].nil? and node.children[1] == :require and node.children[2].type == :str
          yield :requires, node.children[2].children[0].split("/"),
            :line_no => loc.line, :col => loc.column
        end

      when :def
        yield :defs, scope + [node.children[0]],
          :line_no => loc.line, :type => :func, :col => loc.name.column
        yield :end, :end, :line_no => loc.end.line, :type => :func, :col => loc.end.column

      when :defs
        yield :defs, scope + [node.children[1]],
          :line_no => loc.line, :type => :func, :col => loc.name.column
        yield :end, :end, :line_no => loc.end.line, :type => :func, :col => loc.end.column

      when :module, :class
        yield :defs, scope + scoped_name(node.children[0], scope),
          :line_no => loc.line, :type => node.type, :col => loc.name.column
        yield :end, :end, :line_no => loc.end.line, :type => node.type, :col => loc.end.column

      when :casgn
        fqn = scoped_name(node, scope)
        yield :assigns, fqn, :line_no => loc.line, :col => loc.name.column
        yield :defs, fqn, :line_no => loc.line, :col => loc.name.column

      when :lvasgn, :ivasgn, :cvasgn, :gvasgn
        yield :assigns, scope + [node.children[0]], :line_no => loc.line, :col => loc.name.column
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
