require 'rkelly'
require 'babel/transpiler'
require 'sourcemap'

module Starscope::Lang
  module Javascript
    VERSION = 1

    def self.match_file(name)
      name.end_with?('.js')
    end

    def self.extract(path, contents, &block)
      return if path.end_with?('.min.js')

      transform = Babel::Transpiler.transform(contents,
                                              'stage' => 0,
                                              'blacklist' => ['validation.react'],
                                              'externalHelpers' => true,
                                              'compact' => false,
                                              'sourceMaps' => true)
      map = SourceMap::Map.from_hash(transform['map'])
      ast = RKelly::Parser.new.parse(transform['code'])
      lines = contents.lines.to_a

      return unless ast

      found = extract_methods(ast, map, lines, &block)

      found = extract_var_decls(ast, map, lines, found, &block)

      extract_var_reads(ast, map, lines, found, &block)
    end

    def self.extract_methods(ast, map, lines, &block)
      found = {}

      ast.each do |node|
        case node
        when RKelly::Nodes::FunctionExprNode, RKelly::Nodes::FunctionDeclNode
          line = find_line(node.range.from, map, lines, node.value)
          next unless line

          type = :func
          type = :class if lines[line - 1].include?("class #{node.value}")

          yield :defs, node.value, line_no: line, type: type
          found[node.value] ||= Set.new
          found[node.value].add(line)

          next if type == :class

          mapping = map.bsearch(SourceMap::Offset.new(node.range.to.line, node.range.to.char))
          if lines[mapping.original.line - 1].include? '}'
            yield :end, '}', line_no: mapping.original.line, type: type
          else
            yield :end, '', line_no: mapping.original.line, type: type, col: mapping.original.column
          end
        when RKelly::Nodes::FunctionCallNode
          name = node_name(node.value)
          next unless name

          node = node.arguments.value[0] if name == 'require' && !node.value.is_a?(RKelly::Nodes::DotAccessorNode)

          line = find_line(node.range.from, map, lines, name)
          next unless line

          found[name] ||= Set.new
          found[name].add(line)

          if name == 'require' && node.is_a?(RKelly::Nodes::StringNode)
            yield :requires, node.value[1...-1], line_no: line
          else
            yield :calls, name, line_no: line
          end
        end
      end

      found
    end

    def self.extract_var_decls(ast, map, lines, found, &block)
      ast.each do |node|
        next unless node.is_a? RKelly::Nodes::VarDeclNode

        line = find_line(node.range.from, map, lines, node.name)
        next unless line

        if node.value.is_a?(RKelly::Nodes::AssignExprNode) &&
           node.value.value.is_a?(RKelly::Nodes::FunctionCallNode) &&
           node.value.value.value.is_a?(RKelly::Nodes::ResolveNode) &&
           node.value.value.value.value == 'require'
          found[node.name] ||= Set.new
          found[node.name].add(line)
          next
        end

        next if found[node.name] && found[node.name].include?(line)
        yield :defs, node.name, line_no: line
        found[node.name] ||= Set.new
        found[node.name].add(line)
      end

      found
    end

    def self.extract_var_reads(ast, map, lines, found, &block)
      ast.each do |node|
        name = node_name(node)
        next unless name

        line = find_line(node.range.from, map, lines, name)
        next unless line

        next if found[name] && found[name].include?(line)
        yield :reads, name, line_no: line
      end
    end

    def self.node_name(node)
      case node
      when RKelly::Nodes::DotAccessorNode
        node.accessor
      when RKelly::Nodes::ResolveNode
        node.value
      end
    end

    def self.find_line(from, map, lines, name)
      mapping = map.bsearch(SourceMap::Offset.new(from.line, from.char))
      return unless mapping

      line = lines[mapping.original.line - 1]
      return unless line.include?(name) || (name == 'require' && line.include?('import'))

      mapping.original.line
    end
  end
end
