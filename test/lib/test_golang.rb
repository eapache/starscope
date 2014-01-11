require_relative '../test_helper'

class TestGolang < MiniTest::Unit::TestCase
  def setup
    @db = {}
    StarScope::Lang::Go.extract('test/files/sample_golang.go') do |tbl, key, args|
      key = key.to_sym
      @db[tbl] ||= {}
      @db[tbl][key] ||= []
      @db[tbl][key] << args
    end
  end

  def test_function_defs
    assert @db.keys.include? :defs
  end
end
