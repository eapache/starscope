require_relative '../../test_helper'

describe Starscope::Lang::Javascript do
  before do
    @db = {}
    Starscope::Lang::Javascript.extract(JAVASCRIPT_EXAMPLE, File.read(JAVASCRIPT_EXAMPLE)) do |tbl, name, args|
      @db[tbl] ||= []
      @db[tbl] << Starscope::DB.normalize_record(JAVASCRIPT_EXAMPLE, name, args)
    end
  end

  it 'must match js files' do
    _(Starscope::Lang::Javascript.match_file(JAVASCRIPT_EXAMPLE)).must_equal true
  end

  it 'must not match non-js files' do
    _(Starscope::Lang::Javascript.match_file(RUBY_SAMPLE)).must_equal false
    _(Starscope::Lang::Javascript.match_file(EMPTY_FILE)).must_equal false
  end

  it 'must identify definitions' do
    _(@db.keys).must_include :defs
    defs = @db[:defs].map { |x| x[:name][-1] }

    _(defs).must_include :Component
    _(defs).must_include :StyleSheet
    _(defs).must_include :styles
    _(defs).must_include :NavigatorRouteMapper
    _(defs).must_include :LeftButton
    _(defs).must_include :RightButton
    _(defs).must_include :_tabItem
    _(defs).must_include :render
    _(defs).must_include :setRef
    _(defs).must_include :route
    _(defs).must_include :foo
    _(defs).must_include :MyStat
    _(defs).must_include :myStatFunc
    _(defs).must_include :bracelessMethod

    _(defs).wont_include :setStyle
    _(defs).wont_include :setState
    _(defs).wont_include :fontFamily
    _(defs).wont_include :navigator
    _(defs).wont_include :madness
    _(defs).wont_include :React
  end

  it 'must only tag static classes once' do
    _(@db[:defs].count { |x| x[:name][-1] == :MyStat }).must_equal 1
  end

  it 'must identify endings' do
    _(@db.keys).must_include :end
    _(@db[:end].count).must_equal 12

    # bracelessMethod doesn't have a taggable end token so
    # we have to do a little dancing with an empty name and a precise column
    _(@db[:end][0][:name]).must_equal [:'']
    _(@db[:end][0][:col]).must_equal 27
  end

  it 'must identify function calls' do
    _(@db.keys).must_include :calls
    calls = @db[:calls].group_by { |x| x[:name][-1] }

    _(calls.keys).must_include :create
    _(calls.keys).must_include :setStyle
    _(calls.keys).must_include :pop
    _(calls.keys).must_include :fetchData
    _(calls.keys).must_include :setState
    _(calls.keys).must_include :func1

    _(calls[:pop].count).must_equal 1
    _(calls[:_tabItem].count).must_equal 3
  end

  it 'must identify module requires' do
    _(@db.keys).must_include :requires
    requires = @db[:requires].group_by { |x| x[:name][-1] }

    _(requires.keys).must_include :'foo-bar'
    _(requires.keys).must_include :'react-native'
    _(requires.keys).wont_include :NOPE
    _(requires.keys).wont_include :true
    _(requires.keys).wont_include :false
  end
end
