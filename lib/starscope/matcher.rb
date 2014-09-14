class Starscope::Matcher

  MATCH_TYPES = [:literal_match, :regexp_match]

  def initialize(query, input)
    @query  = query
    @input  = input
    @regexp = Regexp.new(query, Regexp::IGNORECASE)
  rescue RegexpError
    # not a regex, oh well
  end

  def match(record)
    name = record[:name].map {|x| x.to_s}.join('::')

    case
    when name.end_with?(@query)
      :literal_match
    when @regexp && @regexp.match(name)
      :regexp_match
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
