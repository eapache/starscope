require 'minitest/autorun'
require 'minitest/pride'
require File.expand_path('../../lib/starscope.rb', __FILE__)

FIXTURES="test/fixtures"

GOLANG_SAMPLE = "#{FIXTURES}/sample_golang.go"
RUBY_SAMPLE = "#{FIXTURES}/sample_ruby.rb"
EMPTY_FILE = "#{FIXTURES}/empty"
