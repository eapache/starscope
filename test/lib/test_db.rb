require_relative '../test_helper'

describe StarScope::DB do

  before do
    @db = StarScope::DB.new(false)
  end

  it "must raise on invalid tables" do
    proc {@db.dump_table(:foo)}.must_raise StarScope::DB::NoTableError
  end

  it "must correctly add paths" do
    paths = [GOLANG_SAMPLE, 'test/files']
    @db.add_paths(paths)
    @db.instance_eval('@paths').must_equal paths
    @db.instance_eval('@files').keys.must_include GOLANG_SAMPLE
    @db.instance_eval('@files').keys.must_include RUBY_SAMPLE
  end

  it "must correctly pick up new files in old paths" do
    @db.instance_eval('@paths = ["test/files"]')
    @db.update
    files = @db.instance_eval('@files').keys
    files.must_include GOLANG_SAMPLE
    files.must_include RUBY_SAMPLE
  end

  it "must correctly remove old files in existing paths" do
    @db.instance_eval('@paths = ["test/files"]')
    @db.instance_eval('@files = {"test/files/foo"=>"2012-01-01"}')
    @db.instance_eval('@files').keys.must_include 'test/files/foo'
    @db.update
    @db.instance_eval('@files').keys.wont_include 'test/files/foo'
  end

  it "must correctly load an old DB file" do
    @db.load('test/files/db_old.json.gz')
    @db.instance_eval('@paths').must_equal ['test/files']
    @db.instance_eval('@files').keys.must_include GOLANG_SAMPLE
    @db.instance_eval('@files').keys.must_include RUBY_SAMPLE
  end

end
