require File.expand_path('../../test_helper', __FILE__)

class TestStarScope < Minitest::Test

  EXEC = 'bundle exec bin/starscope'

  def test_help
    `#{EXEC} -h`.each_line do |line|
      assert line.length <= 80
    end
  end

end
