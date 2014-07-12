require File.expand_path('../../test_helper', __FILE__)

class TestStarScope < Minitest::Test

  BASE = "bundle exec bin/starscope --quiet"
  EXTRACT = "#{BASE} --no-read --no-write ./test/fixtures"

  def test_help
    `#{BASE} -h`.each_line do |line|
      assert line.length <= 80
    end
  end

  def test_version
    assert `#{BASE} -v`.chomp == StarScope::VERSION
  end

  def test_summary
    lines = `#{EXTRACT} -s`.lines
  end

  def test_dump
    lines = `#{EXTRACT} -d requires`.lines.to_a
    assert lines[1].split.first == 'date'
    assert lines[2].split.first == 'zlib'
  end

  def test_query
    `#{EXTRACT} -q calls,add_file`.each_line do |line|
      assert line.split[0..2] == ["StarScope", "DB", "add_file"]
    end
  end

end
