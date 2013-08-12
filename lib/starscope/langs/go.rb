module StarScope::Lang
  module Go
    def self.match_file(name)
      name =~ /.*\.go$/
    end

    def self.extract(file)
      stack = []
      scope = []
      str = File.readlines(file).each_with_index do |line, line_no|
        # strip single-line comments like // foo
        match = /(.*)\/\//.match(line)
        if match
          line = match[0]
        end
        # strip single-line comments like foo /* foo */ foo
        match = /(.*?)\/\*.*\*\/(.*)/.match(line)
        if match
          line = match[0] + match[1]
        end
        # strip end-of-line comment starters like foo /* foo \n
        match = /(.*?)\/\*/.match(line)
        if match
          line = match[0] + match[1]
          ends_with_comment = true
        else
          ends_with_comment = false
        end
        # poor-man's parser
        case stack[-1]
        when :struct
          case line
          when /\s*(\w+)\s+\w+/
            yield :defs, $1, line_no: line_no+1, scope: scope
          when /}/
            stack.pop
            scope.pop
          end
        when :def
          case line
          when /\s*(\w+)\s+/
            yield :defs, $1, line_no: line_no+1, scope: scope
          when /\)/
            stack.pop
          end
        when :import
          case line
          when /"(\w+)"/
            name = $1.split('/')
            yield :imports, name[-1], line_no: line_no+1, scope: name[0...-1]
          when /\)/
            stack.pop
          end
        else
          if stack[-1] == :func and /^}/ =~ line
            stack.pop
          end
          case line
          when /^func\s+(\w+)\(/
            yield :defs, $1, line_no: line_no+1, scope: scope
            stack.push(:func)
          when /^func\s+\(\w+\s+\*?(\w+)\)\s*(\w+)\(/
            yield :defs, $2, line_no: line_no+1, scope: scope + [$1]
            stack.push(:func)
          when /^package\s+(\w+)/
            yield :defs, $1, line_no: line_no+1, scope: scope
            scope.push($1)
          when /^type\s+(\w+)\s+struct\s*{/
            yield :defs, $1, line_no: line_no+1, scope: scope
            scope.push($1)
            stack.push(:struct)
          when /^type\s+(\w+)/
            yield :defs, $1, line_no: line_no+1, scope: scope
          when /^import\s+"(\w+)"/
            name = $1.split('/')
            yield :imports, name[-1], line_no: line_no+1, scope: name[0...-1]
          when /^import\s+\(/
            stack.push(:import)
          when /^var\s+\(/
            stack.push(:def)
          when /^var\s+(\w+)\s+\w+/
            yield :defs, $1, line_no: line_no+1, scope: scope
          when /^const\s+\(/
            stack.push(:def)
          when /^const\s+(\w+)\s+\w+/
            yield :defs, $1, line_no: line_no+1, scope: scope
          when /^\s+(.*?) :?= /
            $1.split(',').each do |var|
              var = var.strip
              name = var.split('.')
              case name.length
              when 1
                yield :assigns, name[0], line_no: line_no+1, scope: scope
              when 2
                yield :assigns, name[1], line_no: line_no+1, scope: scope + [name[0]]
              end
            end
          end
        end
        # if the line looks like "foo /* foo" then we enter the comment state
        # after parsing the usable part of the line
        if ends_with_comment
          stack.push(:comment)
        end
      end
    end
  end
end
