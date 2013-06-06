#!/usr/bin/ruby

lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "starscope"

if ARGV.count == 0
  paths = ['.']
else
  paths = ARGV
end

scope = StarScope::DB.new(paths)
puts scope
