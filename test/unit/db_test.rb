require File.expand_path('../../test_helper', __FILE__)
require 'tempfile'

describe Starscope::DB do

  def validate(db)
    files = db.metadata(:files)
    files.keys.must_include GOLANG_SAMPLE
    files.keys.must_include RUBY_SAMPLE
    files[GOLANG_SAMPLE][:last_updated].must_equal File.mtime(GOLANG_SAMPLE).to_i
    files[RUBY_SAMPLE][:last_updated].must_equal File.mtime(RUBY_SAMPLE).to_i

    tbls = db.instance_eval('@tables')
    tbls.must_include :defs
    defs = tbls[:defs].map {|x| x[:name][-1]}
    defs.must_include :DB
    defs.must_include :NoTableError
    defs.must_include :load
    defs.must_include :update
    defs.must_include :files_from_path
    defs.must_include :single_var
    defs.must_include :single_const
  end

  before do
    @db = Starscope::DB.new(Starscope::Output.new(:quiet))
  end

  it "must raise on invalid tables" do
    proc {@db.records(:foo)}.must_raise Starscope::DB::NoTableError
  end

  it "must add paths" do
    paths = [GOLANG_SAMPLE, "#{FIXTURES}/**/*"]
    @db.add_paths(paths)
    @db.metadata(:paths).must_equal paths
    validate(@db)
  end

  it "must add excludes" do
    paths = [GOLANG_SAMPLE, "#{FIXTURES}/**/*"]
    @db.add_paths(paths)
    @db.add_excludes(["#{FIXTURES}/**"])
    files = @db.metadata(:files).keys
    files.wont_include RUBY_SAMPLE
    files.wont_include GOLANG_SAMPLE
    tbls = @db.instance_eval('@tables')
    tbls[:defs].must_be_empty
    tbls[:end].must_be_empty
  end

  it "must pick up new files in old paths" do
    @db.instance_eval("@meta[:paths] = [\"#{FIXTURES}/**/*\"]")
    @db.update
    validate(@db)
  end

  it "must remove old files in existing paths" do
    @db.instance_eval("@meta[:paths] = [\"#{FIXTURES}/**/*\"]")
    @db.instance_eval("@meta[:files] = {\"#{FIXTURES}/foo\" => {:last_updated=>1}}")
    @db.update
    @db.metadata(:files).keys.wont_include "#{FIXTURES}/foo"
  end

  it "must update stale existing files" do
    @db.instance_eval("@meta[:paths] = [\"#{FIXTURES}/**/*\"]")
    @db.instance_eval("@meta[:files] = {\"#{GOLANG_SAMPLE}\" => {:last_updated=>1}}")
    @db.instance_eval("@tables[:defs] = [{:file => \"#{GOLANG_SAMPLE}\"}]")
    @db.update
    validate(@db)
  end

  it "must update unchanged existing files with old extractor versions" do
    @db.instance_eval("@meta[:paths] = [\"#{FIXTURES}/**/*\"]")
    @db.instance_eval("@meta[:langs] = {:Go => 0}")
    @db.instance_eval("@meta[:files] = {\"#{GOLANG_SAMPLE}\" => {:last_updated=>#{File.mtime(GOLANG_SAMPLE).to_i}, :lang => :Go}}")
    @db.instance_eval("@tables[:defs] = [{:file => \"#{GOLANG_SAMPLE}\"}]")
    @db.update
    validate(@db)
  end

  it "must load an old DB file" do
    @db.load("#{FIXTURES}/db_old.json.gz")
    @db.metadata(:paths).must_equal ["#{FIXTURES}/**/*"]
    validate(@db)
  end

  it "must round-trip a database" do
    file = Tempfile.new('starscope_test')
    begin
      @db.add_paths([FIXTURES])
      @db.save(file.path)
      tmp = Starscope::DB.new(Starscope::Output.new(:quiet))
      tmp.load(file.path)
      validate(tmp)
    ensure
      file.close
      file.unlink
    end
  end

  it "must run queries" do
    @db.add_paths([FIXTURES])
    @db.query(:calls, "abc").must_equal []
    @db.query(:defs, "xyz").must_equal []
    @db.query(:calls, "add_file").length.must_equal 3
  end

  it "must symbolize compound name" do
    rec = Starscope::DB.normalize_record(:foo, ["a", :b], {})
    rec[:name].must_equal [:a, :b]
  end

  it "must symbolize and array-wrap simple name" do
    rec = Starscope::DB.normalize_record(:foo, "a", {})
    rec[:name].must_equal [:a]
  end

end
