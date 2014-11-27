module Starscope::Queryable

  def query(tables, value)
    tables = [tables] if tables.is_a?(Symbol)
    tables.each { |t| raise NoTableError, "Table '#{t}' not found" unless @tables[t] }
    input = Enumerator.new do |y|
      tables.each do |t|
        @tables[t].each do |elem|
          y << elem
        end
      end
    end

    run_query(value, input)
  end

  private

  MATCH_TYPES = [:literal_match, :regexp_match]

  def run_query(query, input)
    begin
      regexp = Regexp.new(query, Regexp::IGNORECASE)
    rescue RegexpError
      # not a regex, oh well
    end

    results = input.group_by {|x| match(x, query, regexp)}

    MATCH_TYPES.each do |type|
       next if results[type].nil? or results[type].empty?
       return results[type]
     end

     return []
  end

  def match(record, query, regexp)
    name = record[:name].map {|x| x.to_s}.join('::')

    case
    when name.end_with?(query)
      :literal_match
    when regexp && regexp.match(name)
      :regexp_match
    end
  end

end
