module Starscope::Lang
  module Go
    VERSION = 1

    FUNC_CALL = /([\w\.]*?\w)\(/
    END_OF_BLOCK = /^\s*\}\s*$/
    END_OF_GROUP = /^\s*\)\s*$/
    STRING_LITERAL = /".+?"/
    BUILTIN_FUNCS = %w(new make len close copy delete int int8 int16 int32 int64 uint uint8 uint16 uint32 uint64 string byte)
    CONTROL_KEYS = %w(if for switch case)

    def self.match_file(name)
      name.end_with?('.go')
    end

    def self.extract(path, contents, &block)
      stack = []
      scope = []
      contents.lines.each_with_index do |line, line_no|
        line_no += 1 # zero-index to one-index

        # strip single-line comments like // foo
        match = %r{//}.match(line)
        line = match.pre_match if match
        # strip single-line comments like foo /* foo */ foo
        match = %r{/\*.*\*/}.match(line)
        line = match.pre_match + match.post_match if match
        # strip end-of-line comment starters like foo /* foo \n
        match = %r{/\*}.match(line)
        line = match.pre_match if match
        ends_with_comment = !match.nil?

        # if we're in a block comment, wait for it to end
        if stack[-1] == :comment
          match = %r{\*/(.*)}.match(line)
          next unless match
          line = match[1]
          stack.pop
        end

        if stack[-1] != :import && !line.start_with?('import')
          # strip string literals like "foo" unless they're part of an import
          pos = 0
          while match = STRING_LITERAL.match(line[pos..-1])
            eos = find_end_of_string(line, match.begin(0))
            line = line[0..match.begin(0)] + line[eos..-1]
            pos += match.begin(0) + 2
          end
        end

        # poor-man's parser
        case stack[-1]
        when :struct
          case line
          when END_OF_BLOCK
            end_block(line_no, scope, stack, &block)
          when /(.+)\s+\w+/
            parse_def(Regexp.last_match(1), line_no, scope, &block)
          end
        when :interface
          case line
          when END_OF_BLOCK
            end_block(line_no, scope, stack, &block)
          when /(\w+)\(.*\)\s+/
            yield :defs, scope + [Regexp.last_match(1)], :line_no => line_no
          end
        when :def
          case line
          when END_OF_GROUP
            stack.pop
          when /(.+)\s*=.*/
            parse_def(Regexp.last_match(1), line_no, scope, &block)
            parse_call(line, line_no, scope, &block)
          else
            parse_def(line, line_no, scope, &block)
          end
        when :import
          case line
          when END_OF_GROUP
            stack.pop
          when /"(.+)"/
            name = Regexp.last_match(1).split('/')
            yield :imports, name, :line_no => line_no
          end
        when :func
          case line
          when /^\}/
            yield :end, '}', :line_no => line_no, :type => :func
            stack.pop
          else
            parse_new_line(line, line_no, scope, stack, &block)
          end
        else
          parse_new_line(line, line_no, scope, stack, &block)
        end

        # if the line looks like "foo /* foo" then we enter the comment state
        # after parsing the usable part of the line
        stack.push(:comment) if ends_with_comment
      end
    end

    # handles new lines (when not in the middle of an existing definition)
    def self.parse_new_line(line, line_no, scope, stack, &block)
      case line
      when /^func\s+(\w+)\(/
        yield :defs, scope + [Regexp.last_match(1)], :line_no => line_no, :type => :func
        stack.push(:func)
      when /^func\s+\(\w+\s+\*?(\w+)\)\s*(\w+)\(/
        yield :defs, scope + [Regexp.last_match(1), Regexp.last_match(2)], :line_no => line_no, :type => :func
        stack.push(:func)
      when /^package\s+(\w+)/
        scope.push(Regexp.last_match(1))
        yield :defs, scope, :line_no => line_no, :type => :package
      when /^type\s+(\w+)\s+struct\s*\{/
        scope.push(Regexp.last_match(1))
        stack.push(:struct)
        yield :defs, scope, :line_no => line_no, :type => :class
      when /^type\s+(\w+)\s+interface\s*\{/
        scope.push(Regexp.last_match(1))
        stack.push(:interface)
        yield :defs, scope, :line_no => line_no, :type => :class
      when /^type\s+(\w+)/
        yield :defs, scope + [Regexp.last_match(1)], :line_no => line_no, :type => :type
      when /^import\s+"(.+)"/
        name = Regexp.last_match(1).split('/')
        yield :imports, name, :line_no => line_no
      when /^import\s+\(/
        stack.push(:import)
      when /^var\s+\(/
        stack.push(:def)
      when /^var\s+(\w+)\s/
        yield :defs, scope + [Regexp.last_match(1)], :line_no => line_no
        parse_call(line, line_no, scope, &block)
      when /^const\s+\(/
        stack.push(:def)
      when /^const\s+(\w+)\s/
        yield :defs, scope + [Regexp.last_match(1)], :line_no => line_no
        parse_call(line, line_no, scope, &block)
      when /^\s+(.*?) :?=[^=]/
        Regexp.last_match(1).split(' ').each do |var|
          next if CONTROL_KEYS.include?(var)
          name = var.delete(',').split('.')
          next if name[0] == '_' # assigning to _ is a discard in golang
          if name.length == 1
            yield :assigns, scope + [name[0]], :line_no => line_no
          else
            yield :assigns, name, :line_no => line_no
          end
        end
        parse_call(line, line_no, scope, &block)
      else
        parse_call(line, line_no, scope, &block)
      end
    end

    def self.parse_call(line, line_no, scope)
      line.scan(FUNC_CALL) do |match|
        name = match[0].split('.').select { |chunk| !chunk.empty? }
        if name.length == 1
          next if name[0] == 'func'
          if BUILTIN_FUNCS.include?(name[0])
            yield :calls, name[0], :line_no => line_no
          else
            yield :calls, scope + [name[0]], :line_no => line_no
          end
        else
          yield :calls, name, :line_no => line_no
        end
      end
    end

    def self.parse_def(line, line_no, scope)
      # if it doesn't start with a valid identifier character, it's probably
      # part of a multi-line literal and we should skip it
      return unless line =~ /^\s*[[:alpha:]_]/

      line.split.each do |var|
        yield :defs, scope + [var.delete(',')], :line_no => line_no
        break unless var.end_with?(',')
      end
    end

    def self.end_block(line_no, scope, stack)
      yield :end, scope + ['}'], :line_no => line_no, :type => :class
      stack.pop
      scope.pop
    end

    def self.find_end_of_string(line, start)
      escape = false
      (start + 1...line.length).each do |i|
        if escape
          escape = false
        elsif line[i].chr == '\\'
          escape = true
        elsif line[i].chr == '"'
          return i
        end
      end

      line.length
    end
  end
end
