module StarScope::Lang
  module Go
    def self.match_file(name)
      name =~ /.*\.go$/
    end

    def self.extract(file)
      stack = []
      str = File.readlines(file).each_with_index do |line, line_no|
        # strip single-line comments like // foo
        match = /(.*)\/\//.match(line)
        if match
          line = match[0]
        end
        # poor-man's parser
        case stack[-1]
        when :comment
          if /\*\// =~ line
            stack.pop
          end
        when :struct
          if /}/ =~ line
            stack.pop
          end
        when :def
          if /\)/ =~ line
            stack.pop
          end
        when :import
          if /\)/ =~ line
            stack.pop
          end
        else
          case line
          when /^func\s+(\w+)\(/
            yield :defs, $1, line_no: line_no+1
          when /^package\s+(\w+)/
            yield :defs, $1, line_no: line_no+1
          when /^type\s+(\w+)\s+struct\s*{/
            yield :defs, $1, line_no: line_no+1
            stack.push(:struct)
          when /^type\s+(\w+)/
            yield :defs, $1, line_no: line_no+1
          when /^import\s+(\w+)/
            yield :imports, $1, line_no: line_no+1
          when /^var/
          when /^const/
          end
        end
      end
    end
  end
end
