require_relative '../test_helper'

describe 'starscope executable script' do
  BASE = 'bundle exec bin/starscope --quiet'.freeze
  EXTRACT = "#{BASE} --no-read --no-write #{FIXTURES}".freeze

  it 'must not produce help wider than 80 characters' do
    `#{BASE} -h`.each_line do |line|
      _(line.length).must_be :<=, 80
    end
  end

  it 'must produce the right version' do
    _(`#{BASE} -v`.chomp).must_equal Starscope::VERSION
  end

  it 'must produce a valid database summary' do
    lines = `#{EXTRACT} -s`.lines.to_a
    _(lines.length).must_equal 8
  end

  it 'must produce a valid database dump' do
    lines = `#{EXTRACT} -d requires`.lines.to_a
    _(lines[1].split.first).must_equal 'date'
    _(lines[2].split.first).must_equal 'foo-bar'
    _(lines[3].split.first).must_equal 'react-native'
    _(lines[4].split.first).must_equal 'zlib'
  end

  it 'must correctly query the database' do
    `#{EXTRACT} -q calls,add_file`.each_line do |line|
      _(line.split[0..2]).must_equal %w(Starscope DB add_file)
    end

    `#{EXTRACT} -q lang:ruby,calls,add_file`.each_line do |line|
      _(line.split[0..2]).must_equal %w(Starscope DB add_file)
    end

    `#{EXTRACT} -q lang:go,calls,add_file`.each_line do |line|
      _(line).must_equal "No results found.\n"
    end
  end

  it 'must correctly export to cscope' do
    file = Tempfile.new('starscope_test')
    begin
      `#{EXTRACT} -e cscope,#{file.path}`
      _($?.exitstatus).must_equal 0
    ensure
      file.close
      file.unlink
    end
  end

  it 'must correctly export to ctags' do
    file = Tempfile.new('starscope_test')
    begin
      `#{EXTRACT} -e ctags,#{file.path}`
      _($?.exitstatus).must_equal 0
    ensure
      file.close
      file.unlink
    end
  end
end
