require 'rkelly'
require 'babel/transpiler'

module Starscope::Lang
  module Javascript
    VERSION = 0

    def self.match_file(name)
      name.end_with?('.js')
    end

    def self.extract(path, contents, &block)
      transform = Babel::Transpiler.transform(contents, 'optional' => ['es7.functionBind'], 'retainLines' => true)
      ast = RKelly::Parser.new.parse(transform['code'])
      lines = contents.lines.to_a
      found = {}

      ast.each do |node|
        case node
        when RKelly::Nodes::VarDeclNode
          next unless lines[node.line - 1].include? node.name
          yield :defs, node.name, line_no: node.line
          found[node.name] ||= Set.new
          found[node.name].add(node.line)
        when RKelly::Nodes::ObjectLiteralNode
          node.value.each_with_index do |prop, i|
            next unless prop.value.is_a? RKelly::Nodes::FunctionExprNode

            name = prop.name
            if name == 'value' && i > 0 && node.value[i - 1].name == 'key'
              name = node.value[i - 1].value.value[1...-1]
            end

            range = prop.value.function_body.range
            next unless lines[range.from.line - 1].include? name
            yield :defs, name, line_no: range.from.line, type: :func
            yield :end, '}', line_no: range.to.line, type: :func
            found[name] ||= Set.new
            found[name].add(range.from.line)
          end
        when RKelly::Nodes::FunctionCallNode
          next unless node.value.is_a? RKelly::Nodes::DotAccessorNode
          next unless lines[node.range.from.line - 1].include? node.value.accessor
          yield :calls, node.value.accessor, line_no: node.range.from.line
          found[node.value.accessor] ||= Set.new
          found[node.value.accessor].add(node.range.from.line)
        end
      end

      ast.each do |node|
        name = ''

        case node
        when RKelly::Nodes::DotAccessorNode
          name = node.accessor
        when RKelly::Nodes::ResolveNode
          name = node.value
        else
          next
        end

        line = node.range.from.line
        next if found[name] && found[name].include?(line)
        next unless lines[line - 1].include? name
        yield :reads, name, line_no: line
      end
    end
  end
end
