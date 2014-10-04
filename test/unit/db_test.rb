require File.expand_path('../../test_helper', __FILE__)
require 'tempfile'

describe Starscope::DB do

  before do
    @db = Starscope::DB.new(Starscope::Output.new(:quiet))
  end

  it "must raise on invalid tables" do
    proc {
      @db.records(:foo)
    }.must_raise Starscope::DB::NoTableError
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
    @db.records(:defs).must_be_empty
    @db.records(:end).must_be_empty
  end

  it "must pick up new files in old paths" do
    @db.load("#{FIXTURES}/db_added_files.json")
    @db.update

    validate(@db)
  end

  it "must remove old files in existing paths" do
    @db.load("#{FIXTURES}/db_removed_files.json")
    @db.update
    @db.metadata(:files).keys.wont_include "#{FIXTURES}/foo"
  end

  it "must update stale existing files when extractor hasn't changed" do
    @db.load("#{FIXTURES}/db_out_of_date.json")
    @db.metadata(:langs)[:Go].must_be :>=, LANGS[:Go]

    cur_mtime = @db.metadata(:files)[GOLANG_SAMPLE][:last_updated]
    File.expects(:mtime).twice.returns(cur_mtime + 1)
    @db.update

    file = @db.metadata(:files)[GOLANG_SAMPLE]
    file[:last_updated].must_equal cur_mtime + 1
    file[:lang].must_equal :Go
    file[:lines].wont_be_empty
    @db.records(:defs).wont_be_empty
    @db.records(:calls).wont_be_empty
  end

  it "must update unchanged existing files with old extractor versions" do
    @db.load("#{FIXTURES}/db_old_extractor.json")

    cur_mtime = @db.metadata(:files)[GOLANG_SAMPLE][:last_updated]
    File.expects(:mtime).twice.returns(cur_mtime)
    @db.update

    file = @db.metadata(:files)[GOLANG_SAMPLE]
    file[:last_updated].must_equal cur_mtime
    file[:lang].must_equal :Go
    file[:lines].wont_be_empty
    @db.records(:defs).wont_be_empty
    @db.records(:calls).wont_be_empty
  end

  it "must not update file with up-to-date time and extractor" do
    @db.load("#{FIXTURES}/db_up_to_date.json")
    @db.update

    file = @db.metadata(:files)[GOLANG_SAMPLE]
    file[:last_updated].must_equal 10000000000
    @db.tables.must_be_empty
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

  it "must run queries on multiple tables" do
    @db.add_paths([FIXTURES])
    ret = @db.query([:calls, :defs], "foo")
    ret.length.must_equal 1
    ret.first[:name].last.must_equal :foo
  end

  it "must symbolize compound name" do
    rec = Starscope::DB.normalize_record(:foo, ["a", :b], {})
    rec[:name].must_equal [:a, :b]
  end

  it "must symbolize and array-wrap simple name" do
    rec = Starscope::DB.normalize_record(:foo, "a", {})
    rec[:name].must_equal [:a]
  end

  it "must store extractor metadata returned from the `extract` call" do
    extractor = mock('extractor')
    extractor.expects(:match_file).with(GOLANG_SAMPLE).returns(true)
    extractor.expects(:extract).with(GOLANG_SAMPLE).returns({:a => 1})
    extractor.expects(:name).returns('Foo')
    EXTRACTORS.stubs(:each).yields(extractor)

    @db.add_paths([GOLANG_SAMPLE])

    @db.metadata(:files)[GOLANG_SAMPLE][:a].must_equal 1
  end

  private

  def validate(db)
    files = db.metadata(:files)
    files.keys.must_include GOLANG_SAMPLE
    files.keys.must_include RUBY_SAMPLE
    files[GOLANG_SAMPLE][:last_updated].must_equal File.mtime(GOLANG_SAMPLE).to_i
    files[RUBY_SAMPLE][:last_updated].must_equal File.mtime(RUBY_SAMPLE).to_i

    db.records(:defs).wont_be_empty
    db.records(:calls).wont_be_empty
    db.records(:imports).wont_be_empty
    db.records(:requires).wont_be_empty
  end

end
