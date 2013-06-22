class StarScope::Datum
  attr_reader :key, :file

  def initialize(fqn, file, line_no)
    @key = fqn[-1].to_sym
    @scope = fqn[0...-1].map {|x| x.to_sym}
    @file = file
    @line_no = line_no
    @line = File.readlines(file)[line_no-1].chomp
  end

  def score_match(fqn)
    score = 0

    i = -1
    fqn[0...-1].reverse.each do |test|
      if test.to_sym == @scope[i]
        score += 5
      elsif Regexp.new(test, Regexp::IGNORECASE).match(@scope[i])
        score += 2
      end
      i -= 1
    end

    score - @scope.count - i + 1
  end

  def location
    "#{@file}:#{@line_no}"
  end

  def to_s
    str = ""
    str << "#{@scope.join " "} " unless @scope.empty?
    str << "#{@key} -- #{location}"
    str << " (#{@line.strip})"
  end

  def ctag_line
    "#{@key}\t#{@file}\t/^#{@line}$/;"
  end
end
