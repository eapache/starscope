require 'starscope/matcher'

module Starscope
  module Queryable
    def query(tables, value, filters = {})
      tables = [tables] if tables.is_a?(Symbol)
      tables.each { |t| raise Starscope::DB::NoTableError, "Table '#{t}' not found" unless @tables[t] }
      input = Enumerator.new do |y|
        tables.each do |t|
          @tables[t].each do |elem|
            y << elem
          end
        end
      end

      run_query(value, input, filters)
    end

    private

    def run_query(query, input, filters)
      query = Starscope::Matcher.new(query)
      filters.each { |k, v| filters[k] = Starscope::Matcher.new(v) }

      results = input.select { |x| filter(x, filters) }.group_by { |x| match(x, query) }

      Starscope::Matcher::MATCH_TYPES.each do |type|
        next if results[type].nil? || results[type].empty?

        return results[type]
      end

      []
    end

    def filter(record, filters)
      filters.all? do |key, filter|
        target = record[key] || (@meta[:files][record[:file]] || {})[key]
        target && filter.match(target.to_s)
      end
    end

    def match(record, query)
      name = record[:name].map(&:to_s).join('::')

      query.match(name)
    end
  end
end
