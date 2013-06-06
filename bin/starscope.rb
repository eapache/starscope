#!/usr/bin/ruby

lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "starscope"

scope = StarScope::StarScope.new
scope.build_db '.'
scope.print_db
