require File.expand_path('../../test_helper', __FILE__)

class TestStarScope < Minitest::Test

  EXEC = 'bundle exec bin/starscope --no-read --no-write --no-progress ./test/files/'

  def test_help
    `#{EXEC} -h`.each_line do |line|
      assert line.length <= 80
    end
  end

  def test_version
    assert `#{EXEC} -v`.chomp == StarScope::VERSION
  end

  def test_summary
    lines = `#{EXEC} -s`.lines
  end

  def test_dump
    lines = `#{EXEC} -d requires`.lines.to_a
    assert lines[1].split.first == 'date'
    assert lines[2].split.first == 'zlib'
  end

  def test_query
    `#{EXEC} -q calls,add_file`.each_line do |line|
      assert line.split[0..2] == ["StarScope", "DB", "add_file"]
    end
  end

end
