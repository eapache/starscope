require_relative '../test_helper'

describe Starscope::Exportable do
  before do
    @db = Starscope::DB.new(Starscope::Output.new(:quiet))
    @db.add_paths([FIXTURES])
    @buf = StringIO.new
  end

  it 'must export to ctags' do
    @db.export_to(:ctags, @buf, '.')
    @buf.rewind
    lines = @buf.each_line.to_a
    _(lines).must_include(
      "NoTableError\t" \
      "./#{FIXTURES}/sample_ruby.rb\t" \
      "/^  class NoTableError < StandardError; end$/;\"\t" \
      "kind:c\t" \
      "language:Ruby\n"
    )
  end

  it 'must export to ctags with different path prefixes' do
    @db.export_to(:ctags, @buf, '../foo')
    @buf.rewind
    lines = @buf.each_line.to_a
    _(lines).must_include(
      "NoTableError\t" \
      "../foo/#{FIXTURES}/sample_ruby.rb\t" \
      "/^  class NoTableError < StandardError; end$/;\"\t" \
      "kind:c\t" \
      "language:Ruby\n"
    )
  end

  it 'must export to cscope' do
    @db.export_to(:cscope, @buf, '.')
    @buf.rewind
    lines = @buf.each_line.to_a

    _(lines).must_include "\t@#{FIXTURES}/sample_golang.go\n"
    _(lines).must_include "\tgSunday\n"
    _(lines).must_include "\t`add_file\n"
    _(lines).must_include "\t}}\n"
    _(lines).must_include "13 class \n"

    _(lines).wont_include "= [\n"
    _(lines).wont_include "4 LANGS = [\n"
    _(lines).wont_include "116 tmpdb[entry[:file]][entry[:line_no]] ||= []\n"
  end
end
