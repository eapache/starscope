class StarScope::Location
  attr_reader :file, :line

  def initialize(file, line)
    @file = file
    @line = line
  end

  def to_s
    "#{file}:#{line}"
  end
end
