require_relative '../../test_helper'

describe Starscope::Lang::Vue do
  before do
    @frags = []
    Starscope::Lang::Vue.extract(VUE_SAMPLE, File.read(VUE_SAMPLE)) do |tbl, name, args|
      _(tbl).must_equal Starscope::DB::FRAGMENT
      _(name).must_equal :Javascript
      @frags << args
    end
  end

  it 'must match vue files' do
    _(Starscope::Lang::Vue.match_file(VUE_SAMPLE)).must_equal true
  end

  it 'must not match non-vue files' do
    _(Starscope::Lang::ERB.match_file(GOLANG_SAMPLE)).must_equal false
    _(Starscope::Lang::ERB.match_file(EMPTY_FILE)).must_equal false
  end

  it 'must identify fragments' do
    _(@frags.length).must_equal(20)
    _(@frags).must_include({ frag: "import marked from 'marked';\n", line_no: 15 })
    _(@frags).must_include({ frag: "    markdown() {\n", line_no: 25 })
    _(@frags).must_include({ frag: "}\n", line_no: 34 })
  end
end
