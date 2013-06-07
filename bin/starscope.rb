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
    options[:action] = true
  end

  opts.on("-q", "--query QUERY", "Queries the database") do |query|
    options[:query] = query
    options[:action] = true
  end

  opts.on("-r", "--read-db READ", "Reads the database from PATH") do |path|
    options[:read] = path
  end

  opts.on("-u", "--update", "Updates the database being read") do
    options[:update] = true
    options[:action] = true
  end

  opts.on("-w", "--write-db PATH", "Writes the database to PATH") do |path|
    options[:write] = path
    options[:action] = true
  end

end.parse!

abort "Cannot specify both a query and a dump" if options[:query] and options[:dump]
abort "Must have a database to read if updating" if options[:update] and not options[:read]
abort "Must specify an action" if not options[:action]

db = if options[:read]
       Marshal::load(IO.read(options[:read]))
     elsif ARGV.empty?
       StarScope::DB.new(['.'])
     else
       StarScope::DB.new(ARGV)
     end

if options[:dump]
  db.dump
end

if options[:query]
  table, value = options[:query].split(',', 2)
  db.query(table.to_sym, value.to_sym)
end

if options[:update]
  db.update

  # If an update was specified without a specific file to write to,
  # we update the database in-place
  if not options[:write]
    File.open(options[:read],'w') do |file|
      Marshal.dump(db, file)
    end
  end
end

if options[:write]
  File.open(options[:write],'w') do |file|
    Marshal.dump(db, file)
  end
end
