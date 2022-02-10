require_relative '../../test_helper'

describe Starscope::Lang::Golang do
  before do
    @db = {}
    Starscope::Lang::Golang.extract(GOLANG_SAMPLE, File.read(GOLANG_SAMPLE)) do |tbl, name, args|
      @db[tbl] ||= []
      @db[tbl] << Starscope::DB.normalize_record(GOLANG_SAMPLE, name, args)
    end
  end

  it 'must match golang files' do
    _(Starscope::Lang::Golang.match_file(GOLANG_SAMPLE)).must_equal true
  end

  it 'must not match non-golang files' do
    _(Starscope::Lang::Golang.match_file(RUBY_SAMPLE)).must_equal false
    _(Starscope::Lang::Golang.match_file(EMPTY_FILE)).must_equal false
  end

  it 'must identify definitions' do
    _(@db.keys).must_include :defs
    defs = @db[:defs].map { |x| x[:name][-1] }

    _(defs).must_include :a
    _(defs).must_include :b
    _(defs).must_include :c
    _(defs).must_include :ttt
    _(defs).must_include :main
    _(defs).must_include :v1
    _(defs).must_include :v2
    _(defs).must_include :Sunday
    _(defs).must_include :Monday
    _(defs).must_include :single_var_Äunicode
    _(defs).must_include :single_const

    _(defs).wont_include :'0x00'
    _(defs).wont_include :'0x01'
    _(defs).wont_include :'0x02'
    _(defs).wont_include :'0x03'
  end

  it 'must identify endings' do
    _(@db.keys).must_include :end
    _(@db[:end].count).must_equal 7
  end

  it 'must identify function calls' do
    _(@db.keys).must_include :calls
    calls = @db[:calls].group_by { |x| x[:name][-1] }

    _(calls.keys).must_include :a
    _(calls.keys).must_include :b
    _(calls.keys).must_include :c
    _(calls.keys).must_include :ttt
    _(calls.keys).must_include :Errorf

    _(calls[:a].count).must_equal 3
    _(calls[:b].count).must_equal 4
    _(calls[:c].count).must_equal 4
    _(calls[:ttt].count).must_equal 2
    _(calls[:Errorf].count).must_equal 1
  end

  it 'must identify variable assignments' do
    _(@db.keys).must_include :assigns
    assigns = @db[:assigns].group_by { |x| x[:name][-1] }

    _(assigns.keys).must_include :x
    _(assigns.keys).must_include :y
    _(assigns.keys).must_include :z
    _(assigns.keys).must_include :n
    _(assigns.keys).must_include :m
    _(assigns.keys).must_include :msg

    _(assigns[:x].count).must_equal 2
    _(assigns[:y].count).must_equal 1
    _(assigns[:z].count).must_equal 1
    _(assigns[:n].count).must_equal 1
    _(assigns[:m].count).must_equal 2
  end

  it 'must identify imports' do
    _(@db.keys).must_include :imports
    imports = @db[:imports].group_by { |x| x[:name][-1] }

    _(imports.keys).must_include :fmt
  end

  it 'must correctly find the end of string constants' do
    _(Starscope::Lang::Golang.find_end_of_string('"123"foo', 0)).must_equal 4
    _(Starscope::Lang::Golang.find_end_of_string('a"123"foo', 0)).must_equal 1
    _(Starscope::Lang::Golang.find_end_of_string('a"123"foo', 1)).must_equal 5
    _(Starscope::Lang::Golang.find_end_of_string('"1\""foo', 0)).must_equal 4
    _(Starscope::Lang::Golang.find_end_of_string('"1\\""foo', 0)).must_equal 4
    _(Starscope::Lang::Golang.find_end_of_string('"1\\\\\"foo', 0)).must_equal 9
  end
end
