require 'minitest/autorun'
require 'minitest/pride'
require 'mocha/mini_test'
require_relative '../lib/starscope'

FIXTURES = 'test/fixtures'

GOLANG_SAMPLE = "#{FIXTURES}/sample_golang.go"
RUBY_SAMPLE = "#{FIXTURES}/sample_ruby.rb"
ERB_SAMPLE = "#{FIXTURES}/sample_erb.erb"
EMPTY_FILE = "#{FIXTURES}/empty"
