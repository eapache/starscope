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
    assert defs.include? :a
    assert defs.include? :b
    assert defs.include? :c
    assert defs.include? :ttt
    assert defs.include? :main
    assert defs.include? :v1
    assert defs.include? :v2
    assert defs.include? :Sunday
    assert defs.include? :Monday
    assert defs.include? :single_var
    assert defs.include? :single_const

    refute defs.include? :"0x00"
    refute defs.include? :"0x01"
    refute defs.include? :"0x02"
    refute defs.include? :"0x03"
  end

  def test_ends
    assert @db.keys.include? :end
    assert @db[:end].count == 6
  end

  def test_function_calls
    assert @db.keys.include? :calls
    calls = @db[:calls].group_by {|x| x[:name][-1]}
    assert calls.keys.include? :a
    assert calls.keys.include? :b
    assert calls.keys.include? :c
    assert calls.keys.include? :ttt
    assert calls.keys.include? :Errorf
    assert calls[:a].count == 3
    assert calls[:b].count == 4
    assert calls[:c].count == 4
    assert calls[:ttt].count == 2
    assert calls[:Errorf].count == 2
  end

  def test_variable_assigns
    assert @db.keys.include? :assigns
    assigns = @db[:assigns].group_by {|x| x[:name][-1]}
    assert assigns.keys.include? :x
    assert assigns.keys.include? :y
    assert assigns.keys.include? :z
    assert assigns.keys.include? :n
    assert assigns.keys.include? :m
    assert assigns[:x].count == 2
    assert assigns[:y].count == 1
    assert assigns[:z].count == 1
    assert assigns[:n].count == 1
    assert assigns[:m].count == 2
  end
end
