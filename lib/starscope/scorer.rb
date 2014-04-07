class StarScope::Scorer

  def initialize(query)
    @query  = query
    @scoped = query.include?('::')
    @prefix = query.end_with?('::')
    @suffix = query.start_with?('::')
    @regexp = Regexp.new(query, Regexp::IGNORECASE)
  end

  def score(val)
    name = val[:name]
    fullname = name.join('::')

    if @scoped
      # TODO figure out logic for this case
      if @regexp.match(fullname) != nil
        return 40
      end
    else
      if name[-1].to_s == @query
        return 100
      elsif @regexp.match(name[-1]) != nil
        return 80
      elsif @regexp.match(fullname) != nil
        return 20
      end
    end

    return 0
  end

end
