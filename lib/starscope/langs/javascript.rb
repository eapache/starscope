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
                                              'optional' => ['es7.functionBind', 'es7.decorators'],
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
          source = find_source(node.range.from, map, lines, node.name)
          next unless source

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
            source = find_source(range.from, map, lines, name)
            next unless source

            yield :defs, name, line_no: source.line, type: :func
            found[name] ||= Set.new
            found[name].add(source.line)

            mapping = map.bsearch(SourceMap::Offset.new(range.to.line, range.to.char))
            yield :end, :'}', line_no: mapping.original.line, type: :func
          end
        when RKelly::Nodes::FunctionCallNode
          name = node_name(node.value)
          next unless name

          source = find_source(node.range.from, map, lines, name)
          next unless source

          yield :calls, name, line_no: source.line
          found[name] ||= Set.new
          found[name].add(source.line)
        end
      end

      ast.each do |node|
        name = node_name(node)
        next unless name

        source = find_source(node.range.from, map, lines, name)
        next unless source

        next if found[name] && found[name].include?(source.line)
        yield :reads, name, line_no: source.line
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

    def self.find_source(from, map, lines, name)
      mapping = map.bsearch(SourceMap::Offset.new(from.line, from.char))
      return unless mapping
      return unless lines[mapping.original.line - 1].include? name
      mapping.original
    end
  end
end
