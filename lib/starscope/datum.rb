class StarScope::Datum

  def self.build(key, file, args)
    args[:key]  = key
    args[:file] = file

    if args[:line_no]
      args[:line] = File.readlines(file)[args[:line_no]-1].chomp
    end

    if args[:scope]
      args[:scope] = args[:scope].map {|x| x.to_sym}
    end

    args
  end

  def self.score_match(dat, fqn)
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

  def self.to_s(dat)
    str = ""
    str << "#{dat[:scope].join " "} " unless dat[:scope].empty?
    str << "#{dat[:key]} -- #{location dat}"
    str << " (#{dat[:line].strip})"
  end

  def self.ctag_line(dat)
    "#{dat[:key]}\t#{dat[:file]}\t/^#{dat[:line]}$/;"
  end
end
