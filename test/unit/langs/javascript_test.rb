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
    Starscope::Lang::Javascript.match_file(JAVASCRIPT_EXAMPLE).must_equal true
  end

  it 'must not match non-js files' do
    Starscope::Lang::Javascript.match_file(RUBY_SAMPLE).must_equal false
    Starscope::Lang::Javascript.match_file(EMPTY_FILE).must_equal false
  end

  it 'must identify definitions' do
    @db.keys.must_include :defs
    defs = @db[:defs].map { |x| x[:name][-1] }

    defs.must_include :Component
    defs.must_include :StyleSheet
    defs.must_include :styles
    defs.must_include :NavigatorRouteMapper
    defs.must_include :LeftButton
    defs.must_include :RightButton
    defs.must_include :_tabItem
    defs.must_include :render
    defs.must_include :setRef
    defs.must_include :route
    defs.must_include :foo
    defs.must_include :MyStat
    defs.must_include :myStatFunc
    defs.must_include :bracelessMethod

    defs.wont_include :setStyle
    defs.wont_include :setState
    defs.wont_include :fontFamily
    defs.wont_include :navigator
    defs.wont_include :madness
    defs.wont_include :React
  end

  it 'must only tag static classes once' do
    @db[:defs].count { |x| x[:name][-1] == :MyStat }.must_equal 1
  end

  it 'must identify endings' do
    @db.keys.must_include :end
    @db[:end].count.must_equal 12

    # bracelessMethod doesn't have a taggable end token so
    # we have to do a little dancing with an empty name and a precise column
    @db[:end][0][:name].must_equal [:'']
    @db[:end][0][:col].must_equal 27
  end

  it 'must identify function calls' do
    @db.keys.must_include :calls
    calls = @db[:calls].group_by { |x| x[:name][-1] }

    calls.keys.must_include :create
    calls.keys.must_include :setStyle
    calls.keys.must_include :pop
    calls.keys.must_include :fetchData
    calls.keys.must_include :setState
    calls.keys.must_include :func1

    calls[:pop].count.must_equal 1
    calls[:_tabItem].count.must_equal 3
  end

  it 'must identify module requires' do
    @db.keys.must_include :requires
    requires = @db[:requires].group_by { |x| x[:name][-1] }

    requires.keys.must_include :'foo-bar'
    requires.keys.must_include :'react-native'
    requires.keys.wont_include :NOPE
    requires.keys.wont_include :true
    requires.keys.wont_include :false
  end
end
