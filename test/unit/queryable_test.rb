require File.expand_path('../../test_helper', __FILE__)

describe Starscope::Queryable do

  SAMPLE_RECORDS = [
    {:name => [:"[abc"]},
    {:name => [:"not a match"]},
    {:name => [:a, :b, :c, :d]},
  ]

  class MockQuerable
    include Starscope::Queryable
    def initialize
      @tables = {
        :mytable => SAMPLE_RECORDS,
        :empty_table => []
      }
    end
  end

  before do
    @mock = MockQuerable.new
  end

  it "must handle empty input" do
    @mock.query(:empty_table, "foo").must_be_empty
  end

  it "must handle scoped queries" do
    @mock.query(:mytable, "a::b::").must_equal [SAMPLE_RECORDS[2]]
  end

  it "must handle regex queries" do
    @mock.query(:mytable, "a[bc]{2}").must_equal [SAMPLE_RECORDS[0]]

    @mock.query(:mytable, "a.*d").must_equal [SAMPLE_RECORDS[2]]
  end

  it "must handle malformed regexes" do
    @mock.query(:mytable, "[abc").must_equal [SAMPLE_RECORDS[0]]
  end

end
