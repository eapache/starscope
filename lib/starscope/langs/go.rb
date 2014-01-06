module StarScope::Lang
  module Go
    FUNC_CALL = /([\w\.]+?)\(.*\)/
    BUILTIN_FUNCS = ['new', 'make', 'len', 'close', 'copy', 'delete',
                     'int', 'int8', 'int16', 'int32', 'int64',
                     'uint', 'uint8', 'uint16', 'uint32', 'uint64',
                     'string', 'byte']

    def self.match_file(name)
      name =~ /.*\.go$/
    end

    def self.extract(file)
      stack = []
      scope = []
      str = File.readlines(file).each_with_index do |line, line_no|
        line_no += 1 # zero-index to one-index
        # strip single-line comments like // foo
        match = /(.*)\/\//.match(line)
        if match
          line = match[1]
        end
        # strip single-line comments like foo /* foo */ foo
        match = /(.*?)\/\*.*\*\/(.*)/.match(line)
        if match
          line = match[1] + match[2]
        end
        # strip end-of-line comment starters like foo /* foo \n
        match = /(.*?)\/\*/.match(line)
        if match
          line = match[1]
          ends_with_comment = true
        else
          ends_with_comment = false
        end
        # if we're in a block comment, wait for it to end
        if stack[-1] == :comment
          match = /\*\/(.*)/.match(line)
          if match
            line = match[1]
            stack.pop
          else
            next
          end
        end
        # poor-man's parser
        case stack[-1]
        when :struct
          case line
          when /\s*(\w+)\s+\w+/
            yield :defs, $1, line_no: line_no, scope: scope
          when /}/
            yield :end, "}", line_no: line_no, scope: scope, type: :class
            stack.pop
            scope.pop
          end
        when :interface
          case line
          when /\s*(\w+)\(.*\)\s+/
            yield :defs, $1, line_no: line_no, scope: scope
          when /}/
            yield :end, "}", line_no: line_no, scope: scope, type: :class
            stack.pop
            scope.pop
          end
        when :def
          case line
          when /\s*(\w+)\s+/
            yield :defs, $1, line_no: line_no, scope: scope
          when /\)/
            stack.pop
          end
        when :import
          case line
          when /"(.+)"/
            name = $1.split('/')
            yield :imports, name[-1], line_no: line_no, scope: name[0...-1]
          when /\)/
            stack.pop
          end
        else
          if stack[-1] == :func and /^}/ =~ line
            yield :end, "}", line_no: line_no, type: :func
            stack.pop
          end
          case line
          when /^func\s+(\w+)\(/
            yield :defs, $1, line_no: line_no, scope: scope, type: :func
            stack.push(:func)
          when /^func\s+\(\w+\s+\*?(\w+)\)\s*(\w+)\(/
            yield :defs, $2, line_no: line_no, scope: scope + [$1], type: :func
            stack.push(:func)
          when /^package\s+(\w+)/
            yield :defs, $1, line_no: line_no, scope: scope, type: :package
            scope.push($1)
          when /^type\s+(\w+)\s+struct\s*{/
            yield :defs, $1, line_no: line_no, scope: scope, type: :class
            scope.push($1)
            stack.push(:struct)
          when /^type\s+(\w+)\s+interface\s*{/
            yield :defs, $1, line_no: line_no, scope: scope, type: :class
            scope.push($1)
            stack.push(:interface)
          when /^type\s+(\w+)/
            yield :defs, $1, line_no: line_no, scope: scope, type: :type
          when /^import\s+"(.+)"/
            name = $1.split('/')
            yield :imports, name[-1], line_no: line_no, scope: name[0...-1]
          when /^import\s+\(/
            stack.push(:import)
          when /^var\s+\(/
            stack.push(:def)
          when /^var\s+(\w+)\s+\w+/
            yield :defs, $1, line_no: line_no, scope: scope
          when /^const\s+\(/
            stack.push(:def)
          when /^const\s+(\w+)\s+\w+/
            yield :defs, $1, line_no: line_no, scope: scope
          when /^\s+(.*?) :?= ((.*?)\(.*\))?/
            $1.split(',').each do |var|
              var = var.strip
              name = var.split('.')
              case name.length
              when 1
                yield :assigns, name[0], line_no: line_no, scope: scope
              when 2
                yield :assigns, name[1], line_no: line_no, scope: [name[0]]
              end
            end
            if $2
              match = FUNC_CALL.match($2)
              if match
                tmp = parse_call(match[1], line_no, scope)
                yield tmp if tmp
              end
            end
          when FUNC_CALL
            tmp = parse_call($1, line_no, scope)
            yield tmp if tmp
          end
        end
        # if the line looks like "foo /* foo" then we enter the comment state
        # after parsing the usable part of the line
        if ends_with_comment
          stack.push(:comment)
        end
      end
    end

    def self.parse_call(line, line_no, scope)
      name = line.split('.').select {|chunk| not chunk.empty?}
      case name.length
      when 1
        return nil if name[0] == 'func'
        if BUILTIN_FUNCS.include?(name[0])
          return :calls, name[0], line_no: line_no
        else
          return :calls, name[0], line_no: line_no, scope: scope
        end
      else
        return :calls, name[-1], line_no: line_no, scope: name[0...-1]
      end
    end
  end
end
