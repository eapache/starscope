class StarScope::Datum

  def self.build(file, name, args)
    args[:file] = file

    if name.is_a? Array
      args[:name] = name.map {|x| x.to_sym}
    else
      args[:name] = [name.to_sym]
    end

    if args[:line_no]
      args[:line] = File.readlines(file)[args[:line_no]-1].chomp
    end

    args
  end

  def self.score_match(dat, test)
    if dat[:name][-1] == test
      5
    elsif Regexp.new(test, Regexp::IGNORECASE).match(dat[:name].join("::"))
      2
    else
      0
    end
  end

  def self.location(dat)
    "#{dat[:file]}:#{dat[:line_no]}"
  end

  def self.to_s(dat)
    str = ""
    str << "#{dat[:name].join " "} -- #{location dat}"
    str << " (#{dat[:line].strip})"
  end

  def self.ctag_line(dat)
    "#{dat[:name][-1]}\t#{dat[:file]}\t/^#{dat[:line]}$/;"
  end

  def self.cscope_mark(tbl, dat)
    case tbl
    when :end
      case dat[:type]
      when :func
        ret = "}"
      else
        return ""
      end
    when :file
      ret = "@"
    when :defs
      case dat[:type]
      when :func
        ret = "$"
      when :class, :module
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
