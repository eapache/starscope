require File.expand_path('../../test_helper', __FILE__)

class TestRuby < Minitest::Test
  def setup
    @db = {}
    StarScope::Lang::Ruby.extract(RUBY_SAMPLE) do |tbl, name, args|
      @db[tbl] ||= []
      @db[tbl] << StarScope::Record.build(RUBY_SAMPLE, name, args)
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
    defs = @db[:defs].map {|x| x[:name][-1]}
    assert defs.include? :DB
    assert defs.include? :NoTableError
    assert defs.include? :load
    assert defs.include? :update
    assert defs.include? :files_from_path
  end

  def test_constant_defs
    assert @db[:defs].map {|x| x[:name][-1]}.include? :PBAR_FORMAT
  end

  def test_ends
    assert @db.keys.include? :end
    assert @db[:end].count == 13
  end

  def test_function_calls
    assert @db.keys.include? :calls
    calls = @db[:calls].group_by {|x| x[:name][-1]}
    assert calls.keys.include? :add_file
    assert calls.keys.include? :each
    assert calls[:add_file].count == 3
    assert calls[:each].count == 8
  end

  def test_variable_assigns
    assert @db.keys.include? :assigns
    assigns = @db[:assigns].group_by {|x| x[:name][-1]}
    assert assigns.keys.include? :pbar
    assert assigns.keys.include? :PBAR_FORMAT
    assert assigns[:pbar].count == 2
    assert assigns[:PBAR_FORMAT].count == 1
  end
end
