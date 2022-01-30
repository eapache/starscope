module Starscope
  class Matcher
    MATCH_TYPES = %i[literal_match regexp_match].freeze

    def initialize(query)
      @query = query

      begin
        @regexp = Regexp.new(@query, Regexp::IGNORECASE)
      rescue RegexpError
        @regexp = nil # not a regex, oh well
      end
    end

    def match(input)
      if input.end_with?(@query)
        :literal_match
      elsif @regexp&.match(input)
        :regexp_match
      end
    end
  end
end
