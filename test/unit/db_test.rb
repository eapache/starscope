require_relative '../test_helper'
require 'tempfile'

describe Starscope::DB do
  before do
    @db = Starscope::DB.new(Starscope::Output.new(:quiet))
  end

  it 'must raise on invalid tables' do
    _(proc { @db.records(:foo) }).must_raise Starscope::DB::NoTableError
  end

  it 'must add paths' do
    paths = [GOLANG_SAMPLE, "#{FIXTURES}/**/*"]
    @db.add_paths(paths)

    _(@db.metadata(:paths)).must_equal paths
    validate(@db)
  end

  it 'must add excludes' do
    paths = [GOLANG_SAMPLE, "#{FIXTURES}/**/*"]
    @db.add_paths(paths)
    @db.add_excludes(["#{FIXTURES}/**"])

    files = @db.metadata(:files).keys
    _(files).wont_include RUBY_SAMPLE
    _(files).wont_include GOLANG_SAMPLE
    _(@db.records(:defs)).must_be_empty
    _(@db.records(:end)).must_be_empty
  end

  it 'must pick up new files in old paths' do
    @db.load("#{FIXTURES}/db_added_files.json")
    @db.update

    validate(@db)
  end

  it 'must remove old files in existing paths' do
    @db.load("#{FIXTURES}/db_removed_files.json")
    @db.update
    _(@db.metadata(:files).keys).wont_include "#{FIXTURES}/foo"
  end

  it "must update stale existing files when extractor hasn't changed" do
    @db.load("#{FIXTURES}/db_out_of_date.json")
    _(@db.metadata(:langs)[:Golang]).must_be :>=, Starscope::DB::LANGS[:Golang]

    cur_mtime = @db.metadata(:files)[GOLANG_SAMPLE][:last_updated]
    File.expects(:mtime).twice.returns(cur_mtime + 1)
    @db.update

    file = @db.metadata(:files)[GOLANG_SAMPLE]
    _(file[:last_updated]).must_equal cur_mtime + 1
    _(file[:lang]).must_equal :Golang
    _(file[:lines]).wont_be_empty
    _(@db.records(:defs)).wont_be_empty
    _(@db.records(:calls)).wont_be_empty
  end

  it 'must update unchanged existing files with old extractor versions' do
    @db.load("#{FIXTURES}/db_old_extractor.json")

    cur_mtime = @db.metadata(:files)[GOLANG_SAMPLE][:last_updated]
    File.expects(:mtime).twice.returns(cur_mtime)
    @db.update

    file = @db.metadata(:files)[GOLANG_SAMPLE]
    _(file[:last_updated]).must_equal cur_mtime
    _(file[:lang]).must_equal :Golang
    _(file[:lines]).wont_be_empty
    _(@db.records(:defs)).wont_be_empty
    _(@db.records(:calls)).wont_be_empty
  end

  it 'must update unchanged existing files with old sublang extractor versions' do
    @db.load("#{FIXTURES}/db_old_subextractor.json")

    cur_mtime = @db.metadata(:files)[GOLANG_SAMPLE][:last_updated]
    File.expects(:mtime).twice.returns(cur_mtime)
    @db.update

    file = @db.metadata(:files)[GOLANG_SAMPLE]
    _(file[:last_updated]).must_equal cur_mtime
    _(file[:lang]).must_equal :Golang
    _(file[:sublangs]).must_be_empty
    _(file[:lines]).wont_be_empty
    _(@db.records(:defs)).wont_be_empty
    _(@db.records(:calls)).wont_be_empty
  end

  it 'must update unchanged existing files when the extractor has been removed' do
    @db.load("#{FIXTURES}/db_missing_language.json")

    cur_mtime = @db.metadata(:files)[GOLANG_SAMPLE][:last_updated]
    File.expects(:mtime).twice.returns(cur_mtime)
    @db.update

    file = @db.metadata(:files)[GOLANG_SAMPLE]
    _(file[:last_updated]).must_equal cur_mtime
    _(file[:lang]).must_equal :Golang
    _(file[:lines]).wont_be_empty
    _(@db.records(:defs)).wont_be_empty
    _(@db.records(:calls)).wont_be_empty
  end

  it 'must not update file with up-to-date time and extractor' do
    @db.load("#{FIXTURES}/db_up_to_date.json")
    @db.update

    file = @db.metadata(:files)[GOLANG_SAMPLE]
    _(file[:last_updated]).must_equal 10_000_000_000
    _(@db.tables).must_be_empty
  end

  it 'must load an old DB file' do
    @db.load("#{FIXTURES}/db_old.json.gz")
    _(@db.metadata(:paths)).must_equal ["#{FIXTURES}/**/*"]
    validate(@db)
  end

  it 'must round-trip a database' do
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

  it 'must run queries' do
    @db.add_paths([FIXTURES])
    _(@db.query(:calls, 'abc')).must_equal []
    _(@db.query(:defs, 'xyz')).must_equal []
    _(@db.query(:calls, 'add_file').length).must_equal 3
  end

  it 'must run queries on multiple tables' do
    @db.add_paths([FIXTURES])
    ret = @db.query([:calls, :defs], 'foo')
    _(ret.length).must_equal 4
    _(ret.first[:name].last).must_equal :foo
  end

  it 'must symbolize compound name' do
    rec = Starscope::DB.normalize_record(:foo, ['a', :b], {})
    _(rec[:name]).must_equal [:a, :b]
  end

  it 'must symbolize and array-wrap simple name' do
    rec = Starscope::DB.normalize_record(:foo, 'a', {})
    _(rec[:name]).must_equal [:a]
  end

  it 'must store extractor metadata returned from the `extract` call' do
    extractor = mock('extractor')
    extractor.expects(:match_file).with(GOLANG_SAMPLE).returns(true)
    extractor.expects(:extract).with(GOLANG_SAMPLE, File.read(GOLANG_SAMPLE)).returns(a: 1)
    extractor.expects(:name).returns('Foo')
    Starscope::DB.stubs(:extractors).returns([extractor])

    @db.add_paths([GOLANG_SAMPLE])

    _(@db.metadata(:files)[GOLANG_SAMPLE][:a]).must_equal 1
  end

  private

  def validate(db)
    files = db.metadata(:files)
    _(files.keys).must_include GOLANG_SAMPLE
    _(files.keys).must_include RUBY_SAMPLE
    _(files[GOLANG_SAMPLE][:last_updated]).must_equal File.mtime(GOLANG_SAMPLE).to_i
    _(files[RUBY_SAMPLE][:last_updated]).must_equal File.mtime(RUBY_SAMPLE).to_i

    _(db.records(:defs)).wont_be_empty
    _(db.records(:calls)).wont_be_empty
    _(db.records(:imports)).wont_be_empty
    _(db.records(:requires)).wont_be_empty
  end
end
