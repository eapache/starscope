require_relative '../test_helper'

describe Starscope::Exportable do
  before do
    @db = Starscope::DB.new(Starscope::Output.new(:quiet))
    @db.add_paths([FIXTURES])
    @buf = StringIO.new
  end

  it 'must export to ctags' do
    @db.export_to(:ctags, @buf)
    @buf.rewind
    lines = @buf.each_line.to_a
    lines.must_include "NoTableError\t#{FIXTURES}/sample_ruby.rb\t/^  class NoTableError < StandardError; end$/;\"\tkind:c\tlanguage:Ruby\n"
  end

  it 'must export to cscope' do
    @db.export_to(:cscope, @buf)
    @buf.rewind
    lines = @buf.each_line.to_a

    lines.must_include "\t@#{FIXTURES}/sample_golang.go\n"
    lines.must_include "\tgSunday\n"
    lines.must_include "\t`add_file\n"
    lines.must_include "\t}}\n"
    lines.must_include "12 class \n"

    lines.wont_include "= [\n"
    lines.wont_include "4 LANGS = [\n"
    lines.wont_include "116 tmpdb[entry[:file]][entry[:line_no]] ||= []\n"
  end
end
