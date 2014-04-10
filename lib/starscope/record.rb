class StarScope::Record

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

  def self.location(rec)
    "#{rec[:file]}:#{rec[:line_no]}"
  end

  def self.to_s(rec)
    str = ""
    str << "#{rec[:name].join " "} -- #{location rec}"
    str << " (#{rec[:line].strip})"
  end

  def self.ctag_line(rec)
    "#{rec[:name][-1]}\t#{rec[:file]}\t/^#{rec[:line]}$/" + self.ctag_ext(rec)
  end

  def self.ctag_ext(rec)
    s = ";\"\t"
    #TODO implement the many more extensions documented at
    #http://ctags.sourceforge.net/FORMAT
    case rec[:type]
    when :func
      s << "kind:f"
    when :class
      s << "kind:c"
    else
      ""
    end
  end

  def self.cscope_mark(tbl, rec)
    case tbl
    when :end
      case rec[:type]
      when :func
        ret = "}"
      else
        return ""
      end
    when :file
      ret = "@"
    when :defs
      case rec[:type]
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
