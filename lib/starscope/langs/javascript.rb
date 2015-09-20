require 'rkelly'
require 'babel/transpiler'
require 'sourcemap'

module Starscope::Lang
  module Javascript
    VERSION = 0

    def self.match_file(name)
      name.end_with?('.js')
    end

    def self.extract(path, contents, &block)
      transform = Babel::Transpiler.transform(contents,
                                              'optional' => ['es7.functionBind'],
                                              'externalHelpers' => true,
                                              'compact' => false,
                                              'sourceMaps' => true)
      map = SourceMap::Map.from_hash(transform['map'])
      ast = RKelly::Parser.new.parse(transform['code'])
      lines = contents.lines.to_a
      found = {}

      ast.each do |node|
        case node
        when RKelly::Nodes::VarDeclNode
          mapping = map.bsearch(SourceMap::Offset.new(node.range.from.line, node.range.from.char))
          next unless mapping
          source = mapping.original
          next unless lines[source.line - 1].include? node.name
          yield :defs, node.name, line_no: source.line
          found[node.name] ||= Set.new
          found[node.name].add(source.line)
        when RKelly::Nodes::ObjectLiteralNode
          node.value.each_with_index do |prop, i|
            next unless prop.value.is_a? RKelly::Nodes::FunctionExprNode

            name = prop.name
            if name == 'value' && i > 0 && node.value[i - 1].name == 'key'
              name = node.value[i - 1].value.value[1...-1]
            end

            range = prop.value.function_body.range
            mapping = map.bsearch(SourceMap::Offset.new(range.from.line, range.from.char))
            next unless mapping
            source = mapping.original
            next unless lines[source.line - 1].include? name
            yield :defs, name, line_no: source.line, type: :func
            found[name] ||= Set.new
            found[name].add(source.line)

            mapping = map.bsearch(SourceMap::Offset.new(range.to.line, range.to.char))
            yield :end, :'}', line_no: mapping.original.line, type: :func
          end
        when RKelly::Nodes::FunctionCallNode
          case node.value
          when RKelly::Nodes::DotAccessorNode
            name = node.value.accessor
          when RKelly::Nodes::ResolveNode
            name = node.value.value
          else
            next
          end
          mapping = map.bsearch(SourceMap::Offset.new(node.range.from.line, node.range.from.char))
          next unless mapping
          source = mapping.original
          next unless lines[source.line - 1].include? name
          yield :calls, name, line_no: source.line
          found[name] ||= Set.new
          found[name].add(source.line)
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

        mapping = map.bsearch(SourceMap::Offset.new(node.range.from.line, node.range.from.char))
        next unless mapping
        source = mapping.original
        next if found[name] && found[name].include?(source.line)
        next unless lines[source.line - 1].include? name
        yield :reads, name, line_no: source.line
      end
    end
  end
end
