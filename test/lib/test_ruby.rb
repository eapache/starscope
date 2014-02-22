require_relative '../test_helper'

class TestRuby < MiniTest::Unit::TestCase
  def setup
    @db = {}
    StarScope::Lang::Ruby.extract(RUBY_SAMPLE) do |tbl, key, args|
      key = key.to_sym
      @db[tbl] ||= {}
      @db[tbl][key] ||= []
      @db[tbl][key] << args
    end
  end

  def test_recognition
    assert StarScope::Lang::Ruby.match_file(RUBY_SAMPLE)
    assert StarScope::Lang::Ruby.match_file('bin/starscope')
    refute StarScope::Lang::Ruby.match_file(GOLANG_SAMPLE)
    refute StarScope::Lang::Ruby.match_file(EMPTY_FILE)
  end

  def test_function_defs
    assert @db.keys.include? :defs
    defs = @db[:defs].keys
    assert defs.include? :DB
    assert defs.include? :NoTableError
    assert defs.include? :load
    assert defs.include? :update
    assert defs.include? :files_from_path
  end

  def test_function_ends
    assert @db.keys.include? :end
    ends = @db[:end]
    assert ends.keys.count == 1
    assert ends.values.first.count == 13
  end

  def test_function_calls
    assert @db.keys.include? :calls
    calls = @db[:calls]
    assert calls.keys.include? :add_file
    assert calls.keys.include? :each
    assert calls[:add_file].count == 3
    assert calls[:each].count == 8
  end

  def test_variable_assigns
    assert @db.keys.include? :assigns
    assigns = @db[:assigns]
    assert assigns.keys.include? :pbar
    assert assigns.keys.include? :PBAR_FORMAT
    assert assigns[:pbar].count == 2
    assert assigns[:PBAR_FORMAT].count == 1
  end
end
