require File.expand_path('../../test_helper', __FILE__)

class TestBinary < Minitest::Test

  BINARY = 'bundle exec bin/starscope'

  def test_help
    `#{BINARY} -h`.each_line do |line|
      assert line.length <= 80
    end
  end

end
