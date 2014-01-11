require_relative '../test_helper'

describe StarScope::DB do

  before do
    @db = StarScope::DB.new(false)
  end

  it "must raise on invalid tables" do
    proc {@db.dump_table(:foo)}.must_raise StarScope::DB::NoTableError
  end

  it "must accept adding new files and directories" do
    @db.add_paths([GOLANG_SAMPLE, 'lib'])
    @db.instance_eval('@files').keys.must_include GOLANG_SAMPLE
    @db.instance_eval('@files').keys.must_include 'lib/starscope/langs/ruby.rb'
  end

end
