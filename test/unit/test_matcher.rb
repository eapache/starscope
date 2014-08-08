require File.expand_path('../../test_helper', __FILE__)

describe Starscope::Matcher do

  SAMPLE_RECORDS = [
    {:name => [:"[abc"]},
    {:name => [:"not a match"]},
    {:name => [:a, :b, :c, :d]},
  ]

  it "must handle empty input" do
    matcher = Starscope::Matcher.new("foo", [])
    matcher.query.must_be_empty
  end

  it "must handle scoped queries" do
    matcher = Starscope::Matcher.new("a::b::", SAMPLE_RECORDS)
    matcher.query.must_equal [SAMPLE_RECORDS[2]]
  end

  it "must handle regex queries" do
    matcher = Starscope::Matcher.new("a[bc]{2}", SAMPLE_RECORDS)
    matcher.query.must_equal [SAMPLE_RECORDS[0]]

    matcher = Starscope::Matcher.new("a.*d", SAMPLE_RECORDS)
    matcher.query.must_equal [SAMPLE_RECORDS[2]]
  end

  it "must handle malformed regexes" do
    matcher = Starscope::Matcher.new("[abc", SAMPLE_RECORDS)
    matcher.query.must_equal [SAMPLE_RECORDS[0]]
  end

end
