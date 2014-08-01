require File.expand_path('../../test_helper', __FILE__)
require 'tempfile'

describe StarScope::DB do

  def validate(db)
    files = db.instance_eval('@meta[:files]')
    files.keys.must_include GOLANG_SAMPLE
    files.keys.must_include RUBY_SAMPLE
    files[GOLANG_SAMPLE][:last_updated].must_equal File.mtime(GOLANG_SAMPLE).to_i
    files[RUBY_SAMPLE][:last_updated].must_equal File.mtime(RUBY_SAMPLE).to_i

    tbls = db.instance_eval('@tables')
    defs = tbls[:defs].map {|x| x[:name][-1]}
    assert defs.include? :DB
    assert defs.include? :NoTableError
    assert defs.include? :load
    assert defs.include? :update
    assert defs.include? :files_from_path
    assert defs.include? :single_var
    assert defs.include? :single_const
  end

  before do
    @db = StarScope::DB.new(StarScope::Output.new(:quiet))
  end

  it "must raise on invalid tables" do
    proc {@db.dump_table(:foo)}.must_raise StarScope::DB::NoTableError
  end

  it "must add paths" do
    paths = [GOLANG_SAMPLE, "#{FIXTURES}/**/*"]
    @db.add_paths(paths)
    @db.instance_eval('@meta[:paths]').must_equal paths
    validate(@db)
  end

  it "must add excludes" do
    paths = [GOLANG_SAMPLE, "#{FIXTURES}/**/*"]
    @db.add_paths(paths)
    @db.add_excludes(["#{FIXTURES}/**"])
    files = @db.instance_eval('@meta[:files]').keys
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
    @db.instance_eval("@meta[:files]").keys.wont_include "#{FIXTURES}/foo"
  end

  it "must update stale existing files" do
    @db.instance_eval("@meta[:paths] = [\"#{FIXTURES}/**/*\"]")
    @db.instance_eval("@meta[:files] = {\"#{GOLANG_SAMPLE}\" => {:last_updated=>1}}")
    @db.instance_eval("@tables[:defs] = [{:file => \"#{GOLANG_SAMPLE}\"}]")
    @db.update
    validate(@db)
  end

  it "must load an old DB file" do
    @db.load("#{FIXTURES}/db_old.json.gz")
    @db.instance_eval('@meta[:paths]').must_equal ["#{FIXTURES}/**/*"]
    validate(@db)
  end

  it "must round-trip a database" do
    file = Tempfile.new('starscope_test')
    begin
      @db.add_paths(["#{FIXTURES}"])
      @db.save(file.path)
      tmp = StarScope::DB.new(StarScope::Output.new(:quiet))
      tmp.load(file.path)
      validate(tmp)
    ensure
      file.close
      file.unlink
    end
  end

  it "must export to ctags" do
    file = Tempfile.new('starscope_test')
    begin
      @db.add_paths(["#{FIXTURES}"])
      @db.export_ctags(file)
      file.rewind
      lines = file.lines.to_a
      lines.must_include "NoTableError\t#{FIXTURES}/sample_ruby.rb\t/^  class NoTableError < StandardError; end$/;\"\tkind:c\tlanguage:Ruby\n"
    ensure
      file.close
      file.unlink
    end
  end

  it "must export to cscope" do
    file = Tempfile.new('starscope_test')
    begin
      @db.add_paths(["#{FIXTURES}"])
      @db.export_cscope(file)
      file.rewind
      lines = file.lines.to_a

      lines.must_include "\t@#{FIXTURES}/sample_golang.go\n"
      lines.must_include "\tgSunday\n"
      lines.must_include "\t`add_file\n"
      lines.must_include "\t}}\n"
      lines.must_include "13 class \n"

      lines.wont_include "= [\n"
      lines.wont_include "4 LANGS = [\n"
      lines.wont_include "116 tmpdb[entry[:file]][entry[:line_no]] ||= []\n"
    ensure
      file.close
      file.unlink
    end
  end

  it "must run queries" do
    @db.add_paths(["#{FIXTURES}"])
    @db.query(:calls, "abc").must_equal []
    @db.query(:defs, "xyz").must_equal []
    @db.query(:calls, "add_file").length.must_equal 3
  end

end
