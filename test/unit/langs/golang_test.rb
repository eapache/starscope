require File.expand_path('../../../test_helper', __FILE__)

describe Starscope::Lang::Go do
  before do
    @db = {}
    Starscope::Lang::Go.extract(GOLANG_SAMPLE, File.read(GOLANG_SAMPLE)) do |tbl, name, args|
      @db[tbl] ||= []
      @db[tbl] << Starscope::DB.normalize_record(GOLANG_SAMPLE, name, args)
    end
  end

  it 'must match golang files' do
    Starscope::Lang::Go.match_file(GOLANG_SAMPLE).must_equal true
  end

  it 'must not match non-golang files' do
    Starscope::Lang::Go.match_file(RUBY_SAMPLE).must_equal false
    Starscope::Lang::Go.match_file(EMPTY_FILE).must_equal false
  end

  it 'must identify definitions' do
    @db.keys.must_include :defs
    defs = @db[:defs].map { |x| x[:name][-1] }

    defs.must_include :a
    defs.must_include :b
    defs.must_include :c
    defs.must_include :ttt
    defs.must_include :main
    defs.must_include :v1
    defs.must_include :v2
    defs.must_include :Sunday
    defs.must_include :Monday
    defs.must_include :single_var
    defs.must_include :single_const

    defs.wont_include :"0x00"
    defs.wont_include :"0x01"
    defs.wont_include :"0x02"
    defs.wont_include :"0x03"
  end

  it 'must identify endings' do
    @db.keys.must_include :end
    @db[:end].count.must_equal 7
  end

  it 'must identify function calls' do
    @db.keys.must_include :calls
    calls = @db[:calls].group_by { |x| x[:name][-1] }

    calls.keys.must_include :a
    calls.keys.must_include :b
    calls.keys.must_include :c
    calls.keys.must_include :ttt
    calls.keys.must_include :Errorf

    calls[:a].count.must_equal 3
    calls[:b].count.must_equal 4
    calls[:c].count.must_equal 4
    calls[:ttt].count.must_equal 2
    calls[:Errorf].count.must_equal 1
  end

  it 'must identify variable assignments' do
    @db.keys.must_include :assigns
    assigns = @db[:assigns].group_by { |x| x[:name][-1] }

    assigns.keys.must_include :x
    assigns.keys.must_include :y
    assigns.keys.must_include :z
    assigns.keys.must_include :n
    assigns.keys.must_include :m
    assigns.keys.must_include :msg

    assigns[:x].count.must_equal 2
    assigns[:y].count.must_equal 1
    assigns[:z].count.must_equal 1
    assigns[:n].count.must_equal 1
    assigns[:m].count.must_equal 2
  end

  it 'must identify imports' do
    @db.keys.must_include :imports
    imports = @db[:imports].group_by { |x| x[:name][-1] }

    imports.keys.must_include :fmt
  end

  it 'must correctly find the end of string constants' do
    Starscope::Lang::Go.find_end_of_string('"123"foo', 0).must_equal 4
    Starscope::Lang::Go.find_end_of_string('a"123"foo', 0).must_equal 1
    Starscope::Lang::Go.find_end_of_string('a"123"foo', 1).must_equal 5
    Starscope::Lang::Go.find_end_of_string('"1\""foo', 0).must_equal 4
    Starscope::Lang::Go.find_end_of_string('"1\\""foo', 0).must_equal 4
    Starscope::Lang::Go.find_end_of_string('"1\\\\\"foo', 0).must_equal 9
  end
end
