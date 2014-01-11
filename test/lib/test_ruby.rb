require_relative '../test_helper'

class TestRuby < MiniTest::Unit::TestCase
  def setup
    @db = {}
    StarScope::Lang::Ruby.extract('lib/starscope/db.rb') do |tbl, key, args|
      key = key.to_sym
      @db[tbl] ||= {}
      @db[tbl][key] ||= []
      @db[tbl][key] << args
    end
  end

  def test_recognition
    assert StarScope::Lang::Ruby.match_file('lib/starscope/db.rb')
    assert StarScope::Lang::Ruby.match_file('bin/starscope')
    refute StarScope::Lang::Ruby.match_file('test/files/sample_golang.go')
  end
end
