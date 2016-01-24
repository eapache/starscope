require_relative '../../test_helper'

describe Starscope::Lang::ERB do
  before do
    @frags = []
    Starscope::Lang::ERB.extract(ERB_SAMPLE, File.read(ERB_SAMPLE)) do |tbl, name, args|
      tbl.must_equal Starscope::DB::FRAGMENT
      name.must_equal :Ruby
      @frags << args
    end
  end

  it 'must match erb files' do
    Starscope::Lang::ERB.match_file(ERB_SAMPLE).must_equal true
  end

  it 'must not match non-erb files' do
    Starscope::Lang::ERB.match_file(GOLANG_SAMPLE).must_equal false
    Starscope::Lang::ERB.match_file(EMPTY_FILE).must_equal false
  end

  it 'must identify all fragments' do
    @frags.must_equal [{ frag: ' if foo ', line_no: 1 },
                       { frag: ' elsif bar ', line_no: 3 },
                       { frag: ' end ', line_no: 5 },
                       { frag: ' case x', line_no: 8 },
                       { frag: 'when :bar ', line_no: 9 },
                       { frag: ' magic ', line_no: 9 },
                       { frag: ' when :baz', line_no: 9 },
                       { frag: 'when :foo ', line_no: 10 },
                       { frag: ' end ', line_no: 12 },
                       { frag: ' foo ', line_no: 14 },
                       { frag: ' bar ', line_no: 14 },
                       { frag: ' baz ', line_no: 14 }]
  end
end
