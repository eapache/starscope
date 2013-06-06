require "starscope/table"

class StarScope::DB
  attr_reader :table

  def initialize
    @table = {:calls => StarScope::Table.new}
  end
end
