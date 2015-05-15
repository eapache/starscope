require File.expand_path('../../test_helper', __FILE__)

describe Starscope::Output do
  it 'must be quiet' do
    buf = StringIO.new
    out = Starscope::Output.new(:quiet, buf)
    out.normal('foo')
    out.extra('foo')
    buf.size.must_equal 0
  end

  it 'must be normal' do
    buf = StringIO.new
    out = Starscope::Output.new(:normal, buf)
    out.normal('foo')
    out.extra('foo')
    buf.size.must_equal 4
  end

  it 'must be verbose' do
    buf = StringIO.new
    out = Starscope::Output.new(:verbose, buf)
    out.normal('foo')
    out.extra('foo')
    buf.size.must_equal 8
  end
end
