require File.expand_path('../../test_helper', __FILE__)

describe StarScope::Record do

  it "must symbolize compound name" do
    rec = StarScope::Record.build(:foo, ["a", :b], {})
    rec[:name].must_equal [:a, :b]
  end

  it "must symbolize and array-wrap simple name" do
    rec = StarScope::Record.build(:foo, "a", {})
    rec[:name].must_equal [:a]
  end

  it "must read correct line from file" do

    # we interleave the files here to test the cache

    rec = StarScope::Record.build(GOLANG_SAMPLE, :a, {:line_no => 1})
    rec[:line].must_equal "package main"

    rec = StarScope::Record.build(GOLANG_SAMPLE, :a, {:line_no => 66})
    rec[:line].must_equal "\tfmt.Println(t)"

    rec = StarScope::Record.build(RUBY_SAMPLE, :a, {:line_no => 1})
    rec[:line].must_equal "require 'date'"

    rec = StarScope::Record.build(RUBY_SAMPLE, :a, {:line_no => 163})
    rec[:line].must_equal "end"

    rec = StarScope::Record.build(GOLANG_SAMPLE, :a, {:line_no => 67})
    rec[:line].must_equal "}"
  end

end
