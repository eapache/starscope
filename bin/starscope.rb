#!/usr/bin/env ruby

lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'optparse'
require "starscope"

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: starscope.rb [options] [PATHS]"

  opts.on("-d", "--dump-db", "Dumps the database to standard-out") do
    options[:dump] = true
  end

  opts.on("-q", "--query QUERY", "Queries the database") do |query|
    options[:query] = query
  end

  opts.on("-r", "--read-db READ", "Reads the database from PATH") do |path|
    options[:read] = path
  end

  opts.on("-u", "--update", "Updates the database being read") do
    options[:update] = true
  end

  opts.on("-w", "--write-db PATH", "Writes the database to PATH") do |path|
    options[:write] = path
  end

end.parse!

abort "Cannot specify both a query and a dump" if options[:query] and options[:dump]
abort "Must have a database to read if updating" if options[:update] and not options[:read]

db = if options[:read]
       Marshal::load(IO.read(options[:read]))
     elsif ARGV.empty?
       StarScope::DB.new(['.'])
     else
       StarScope::DB.new(ARGV)
     end

if options[:dump]
  puts db
end

if options[:query]
  abort "not yet implemented"
end

if options[:update]
  abort "not yet implemented"
end

if options[:write]
  File.open(options[:write],'w') do |file|
    Marshal.dump(db, file)
  end
end
