class Starscope::Matcher

  MATCH_TYPES = [:full_match, :simple_match, :simple_regexp, :full_regexp]

  def initialize(query, input)
    @query  = query
    @input  = input
    @regexp = Regexp.new(query, Regexp::IGNORECASE)
  rescue RegexpError
    # not a regex, oh well
  end

  def match(record)
    name = record[:name].map {|x| x.to_s}
    fullname = name.join('::')

    case
    when fullname == @query
      :full_match
    when name[-1] == @query
      :simple_match
    when @regexp
      if @regexp.match(name[-1])
        :simple_regexp
      elsif @regexp.match(fullname)
        :full_regexp
      end
    end
  end

  def query
    return [] if @input.empty?

    results = @input.group_by {|x| match(x)}

    MATCH_TYPES.each do |type|
       next if results[type].nil? or results[type].empty?
       return results[type]
     end

     return []
  end

end
