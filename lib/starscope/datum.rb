class StarScope::Datum
  attr_reader :key, :scope, :file, :line

  def initialize(fqn, file, line)
    @key = fqn[-1]
    @scope = fqn[0...-1]
    @file = file
    @line = line
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
