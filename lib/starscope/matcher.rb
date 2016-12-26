module Starscope
  class Matcher
    MATCH_TYPES = [:literal_match, :regexp_match].freeze

    def initialize(query)
      @query = query

      begin
        @regexp = Regexp.new(@query, Regexp::IGNORECASE)
      rescue RegexpError
        @regexp = nil # not a regex, oh well
      end
    end

    def match(input)
      case
      when input.end_with?(@query)
        :literal_match
      when @regexp && @regexp.match(input)
        :regexp_match
      end
    end
  end
end
