require_relative '../test_helper'

describe Starscope::FragmentExtractor do
  module Starscope
    module Lang
      module Dummy
      end
    end
  end

  before do
    @extractor = Starscope::FragmentExtractor.new(
      :Dummy,
      [
        { frag: "def foo; end\n", line_no: 12 },
        { frag: "def bar\n", line_no: 15 },
        { frag: "end\n", line_no: 29 }
      ])
    @reconstructed = "def foo; end\ndef bar\nend"
  end

  it 'must pass reconstructed text to the child' do
    ::Starscope::Lang::Dummy.expects(:extract).with(:foo, @reconstructed)
    @extractor.extract(:foo, '---')
  end

  it 'must pass along extractor metadata from the child' do
    ::Starscope::Lang::Dummy.expects(:extract).returns a: 1, b: 3
    @extractor.extract(:foo, '---').must_equal a: 1, b: 3
  end

  it 'must pass along the name from the child' do
    @extractor.name.must_equal ::Starscope::Lang::Dummy.name
  end

  it 'must override-merge yielded args based on line number' do
    ::Starscope::Lang::Dummy.expects(:extract).yields(:foo, :bar, line_no: 2, foo: :bar)

    @extractor.extract(:foo, '---') do |tbl, name, args|
      tbl.must_equal :foo
      name.must_equal :bar
      args.must_equal line_no: 15, foo: :bar
    end
  end
end
