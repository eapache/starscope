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
    rec = StarScope::Record.build(GOLANG_SAMPLE, :a, {:line_no => 1})
    rec[:line].must_equal "package main"
  end

end
