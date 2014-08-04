require File.expand_path('../../test_helper', __FILE__)

class TestRuby < Minitest::Test
  def setup
    @db = {}
    StarScope::Lang::Ruby.extract(RUBY_SAMPLE) do |tbl, name, args|
      @db[tbl] ||= []
      @db[tbl] << StarScope::DB.build_record(RUBY_SAMPLE, name, args)
    end
  end

  def test_recognition
    assert StarScope::Lang::Ruby.match_file(RUBY_SAMPLE)
    assert StarScope::Lang::Ruby.match_file('bin/starscope')
    refute StarScope::Lang::Ruby.match_file(GOLANG_SAMPLE)
    refute StarScope::Lang::Ruby.match_file(EMPTY_FILE)
  end

  def test_function_defs
    assert_includes @db.keys, :defs
    defs = @db[:defs].map {|x| x[:name][-1]}
    assert_includes defs, :DB
    assert_includes defs, :NoTableError
    assert_includes defs, :load
    assert_includes defs, :update
    assert_includes defs, :files_from_path
  end

  def test_constant_defs
    assert_includes @db[:defs].map {|x| x[:name][-1]}, :PBAR_FORMAT
  end

  def test_ends
    assert_includes @db.keys, :end
    assert_equal 13, @db[:end].count
  end

  def test_function_calls
    assert_includes @db.keys, :calls
    calls = @db[:calls].group_by {|x| x[:name][-1]}
    assert_includes calls.keys, :add_file
    assert_includes calls.keys, :each
    assert_equal 3, calls[:add_file].count
    assert_equal 8, calls[:each].count
  end

  def test_variable_assigns
    assert_includes @db.keys, :assigns
    assigns = @db[:assigns].group_by {|x| x[:name][-1]}
    assert_includes assigns.keys, :pbar
    assert_includes assigns.keys, :PBAR_FORMAT
    assert_includes assigns.keys, :foo
    assert_equal 2, assigns[:pbar].count
    assert_equal 1, assigns[:PBAR_FORMAT].count
    assert_equal 1, assigns[:foo].count

    refute_includes assigns.keys, "=".to_sym
    refute_includes assigns.keys, "<".to_sym
  end
end
