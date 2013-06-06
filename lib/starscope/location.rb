class StarScope::Location
  attr_reader :file, :line

  def initialize(file, line)
    @file = file
    @line = line
  end
end
