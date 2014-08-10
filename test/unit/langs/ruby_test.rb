require File.expand_path('../../../test_helper', __FILE__)

describe Starscope::Lang::Ruby do
  before do
    @db = {}
    Starscope::Lang::Ruby.extract(RUBY_SAMPLE) do |tbl, name, args|
      @db[tbl] ||= []
      @db[tbl] << Starscope::DB.normalize_record(RUBY_SAMPLE, name, args)
    end
  end

  it "must match ruby files" do
    Starscope::Lang::Ruby.match_file(RUBY_SAMPLE).must_equal true
    Starscope::Lang::Ruby.match_file('bin/starscope').must_equal true
  end

  it "must not match non-ruby files" do
    Starscope::Lang::Ruby.match_file(GOLANG_SAMPLE).must_equal false
    Starscope::Lang::Ruby.match_file(EMPTY_FILE).must_equal false
  end

  it "must identify function definitions" do
    @db.keys.must_include :defs
    defs = @db[:defs].map {|x| x[:name][-1]}

    defs.must_include :DB
    defs.must_include :NoTableError
    defs.must_include :load
    defs.must_include :update
    defs.must_include :files_from_path
  end

  it "must identify constant definitions" do
    @db[:defs].map {|x| x[:name][-1]}.must_include :PBAR_FORMAT
  end

  it "must identify endings" do
    @db.keys.must_include :end
    @db[:end].count.must_equal 13
  end

  it "must identify function calls" do
    @db.keys.must_include :calls
    calls = @db[:calls].group_by {|x| x[:name][-1]}

    calls.keys.must_include :add_file
    calls.keys.must_include :each
    calls[:add_file].count.must_equal 3
    calls[:each].count.must_equal 8
  end

  it "must identify variable assignments" do
    @db.keys.must_include :assigns
    assigns = @db[:assigns].group_by {|x| x[:name][-1]}

    assigns.keys.must_include :pbar
    assigns.keys.must_include :PBAR_FORMAT
    assigns.keys.must_include :foo
    assigns[:pbar].count.must_equal 2
    assigns[:PBAR_FORMAT].count.must_equal 1
    assigns[:foo].count.must_equal 1

    assigns.keys.wont_include "=".to_sym
    assigns.keys.wont_include "<".to_sym
  end
end
