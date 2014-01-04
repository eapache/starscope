class StarScope::Datum

  def self.build(file, args)
    args[:file] = file

    if args[:line_no]
      args[:line] = File.readlines(file)[args[:line_no]-1].chomp
    end

    if args[:scope]
      if args[:scope].empty?
        args.delete(:scope)
      else
        args[:scope] = args[:scope].map {|x| x.to_sym}
      end
    end

    args
  end

  def self.score_match(dat, fqn)
    return 0 if not dat[:scope]

    score = 0

    i = -1
    fqn[0...-1].reverse.each do |test|
      if test.to_sym == dat[:scope][i]
        score += 5
      elsif Regexp.new(test, Regexp::IGNORECASE).match(dat[:scope][i])
        score += 2
      end
      i -= 1
    end

    score - dat[:scope].count - i + 1
  end

  def self.location(dat)
    "#{dat[:file]}:#{dat[:line_no]}"
  end

  def self.to_s(key, dat)
    str = ""
    str << "#{dat[:scope].join " "} " if dat[:scope]
    str << "#{key} -- #{location dat}"
    str << " (#{dat[:line].strip})"
  end

  def self.ctag_line(key, dat)
    "#{key}\t#{dat[:file]}\t/^#{dat[:line]}$/;"
  end

  def self.cscope_mark(tbl, dat)
    case tbl
    when :file
      ret = "@"
    when :defs
      case dat[:type]
      when :func
        ret = "$"
      when :class
        ret = "c"
      when :type
        ret = "t"
      else
        ret = "g"
      end
    when :calls
      ret = "`"
    when :requires
      ret = "~\""
    when :imports
      ret = "~<"
    when :assigns
      ret = "="
    else
      return ""
    end

    return "\t" + ret
  end
end
