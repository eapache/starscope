require File.expand_path('../../test_helper', __FILE__)

class TestGolang < Minitest::Test
  def setup
    @db = {}
    StarScope::Lang::Go.extract(GOLANG_SAMPLE) do |tbl, name, args|
      @db[tbl] ||= []
      @db[tbl] << StarScope::Record.build(GOLANG_SAMPLE, name, args)
    end
  end

  def test_recognition
    assert StarScope::Lang::Go.match_file(GOLANG_SAMPLE)
    refute StarScope::Lang::Go.match_file(RUBY_SAMPLE)
    refute StarScope::Lang::Go.match_file(EMPTY_FILE)
  end

  def test_defs
    assert @db.keys.include? :defs
    defs = @db[:defs].map {|x| x[:name][-1]}
    assert_includes defs, :a
    assert_includes defs, :b
    assert_includes defs, :c
    assert_includes defs, :ttt
    assert_includes defs, :main
    assert_includes defs, :v1
    assert_includes defs, :v2
    assert_includes defs, :Sunday
    assert_includes defs, :Monday
    assert_includes defs, :single_var
    assert_includes defs, :single_const

    refute_includes defs, :"0x00"
    refute_includes defs, :"0x01"
    refute_includes defs, :"0x02"
    refute_includes defs, :"0x03"
  end

  def test_ends
    assert @db.keys.include? :end
    assert @db[:end].count == 7
  end

  def test_function_calls
    assert @db.keys.include? :calls
    calls = @db[:calls].group_by {|x| x[:name][-1]}
    assert_includes calls.keys, :a
    assert_includes calls.keys, :b
    assert_includes calls.keys, :c
    assert_includes calls.keys, :ttt
    assert_includes calls.keys, :Errorf
    assert_equal 3, calls[:a].count
    assert_equal 4, calls[:b].count
    assert_equal 4, calls[:c].count
    assert_equal 2, calls[:ttt].count
    assert_equal 1, calls[:Errorf].count
  end

  def test_variable_assigns
    assert @db.keys.include? :assigns
    assigns = @db[:assigns].group_by {|x| x[:name][-1]}
    assert_includes assigns.keys, :x
    assert_includes assigns.keys, :y
    assert_includes assigns.keys, :z
    assert_includes assigns.keys, :n
    assert_includes assigns.keys, :m
    assert_includes assigns.keys, :msg
    assert_equal 2, assigns[:x].count
    assert_equal 1, assigns[:y].count
    assert_equal 1, assigns[:z].count
    assert_equal 1, assigns[:n].count
    assert_equal 2, assigns[:m].count
  end

  def test_imports
    assert_includes @db.keys, :imports
    imports = @db[:imports].group_by {|x| x[:name][-1]}
    assert_includes imports.keys, :fmt
  end

  def test_find_end_of_string
    assert_equal 4, StarScope::Lang::Go.find_end_of_string('"123"foo', 0)
    assert_equal 1, StarScope::Lang::Go.find_end_of_string('a"123"foo', 0)
    assert_equal 5, StarScope::Lang::Go.find_end_of_string('a"123"foo', 1)
    assert_equal 4, StarScope::Lang::Go.find_end_of_string('"1\""foo', 0)
    assert_equal 4, StarScope::Lang::Go.find_end_of_string('"1\\""foo', 0)
    assert_equal 9, StarScope::Lang::Go.find_end_of_string('"1\\\\\"foo', 0)
  end
end
