require 'minitest/autorun'
require 'minitest/pride'
require 'mocha/minitest'
require_relative '../lib/starscope'

FIXTURES = 'test/fixtures'.freeze

GOLANG_SAMPLE = "#{FIXTURES}/sample_golang.go".freeze
JAVASCRIPT_EXAMPLE = "#{FIXTURES}/sample_javascript.js".freeze
RUBY_SAMPLE = "#{FIXTURES}/sample_ruby.rb".freeze
ERB_SAMPLE = "#{FIXTURES}/sample_erb.erb".freeze
EMPTY_FILE = "#{FIXTURES}/empty".freeze
