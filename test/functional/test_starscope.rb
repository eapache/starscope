require File.expand_path('../../test_helper', __FILE__)

class TestStarScope < Minitest::Test

  BASE = "bundle exec bin/starscope --quiet"
  EXTRACT = "#{BASE} --no-read --no-write #{FIXTURES}"

  def test_help
    `#{BASE} -h`.each_line do |line|
      assert line.length <= 80
    end
  end

  def test_version
    assert_equal StarScope::VERSION, `#{BASE} -v`.chomp
  end

  def test_summary
    lines = `#{EXTRACT} -s`.lines.to_a
    assert_equal lines.length, 6
  end

  def test_dump
    lines = `#{EXTRACT} -d requires`.lines.to_a
    assert_equal 'date', lines[1].split.first
    assert_equal 'zlib', lines[2].split.first
  end

  def test_query
    `#{EXTRACT} -q calls,add_file`.each_line do |line|
      assert_equal ["StarScope", "DB", "add_file"], line.split[0..2]
    end
  end

  def test_export_cscope
    file = Tempfile.new('starscope_test')
    begin
      `#{EXTRACT} -e cscope,#{file.path()}`
      assert_equal 0, $?.exitstatus
      `#{EXTRACT} -e ctags,#{file.path()}`
    ensure
      file.close
      file.unlink
    end
  end

  def test_export_ctags
    file = Tempfile.new('starscope_test')
    begin
      `#{EXTRACT} -e ctags,#{file.path()}`
      assert_equal 0, $?.exitstatus
    ensure
      file.close
      file.unlink
    end
  end

end
