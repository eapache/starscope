class StarScope::Datum
  attr_reader :key, :scope, :file, :line

  def initialize(fqn, file, line)
    @key = fqn[-1].to_sym
    @scope = fqn[0...-1].map {|x| x.to_sym}
    @file = file
    @line = line
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
    "#{file}:#{line}"
  end

  def to_s
    if @scope.empty?
      "#{key} -- #{location}"
    else
      "#{@scope.join " "} #{@key} -- #{location}"
    end
  end
end
