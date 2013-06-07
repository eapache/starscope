#!/usr/bin/env ruby

lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'optparse'
require "starscope"

options = {auto: true}
DEFAULT_DB=".starscope.db"

# Options Parsing
OptionParser.new do |opts|
  opts.banner = "Usage: starscope.rb [options] [PATHS]"

  opts.on("-d", "--dump [TABLE]", "Dumps the DB or specified table to standard-out") do |tbl|
    options[:dump] = tbl || true
  end

  opts.on("-n", "--no-auto", "Don't automatically create or update the database") do
    options[:auto] = false
  end

  opts.on("-q", "--query QUERY", "Queries the database") do |query|
    options[:query] = query
  end

  opts.on("-r", "--read-db READ", "Reads the database from PATH instead of #{DEFAULT_DB}") do |path|
    options[:read] = path
  end

  opts.on("-s", "--summary", "Print a database summary to standard-out") do
    options[:summary] = true
  end

  opts.on("-w", "--write-db PATH", "Writes the database to PATH instead of #{DEFAULT_DB}") do |path|
    options[:write] = path
  end

end.parse!

# Load the database
db = StarScope::DB.new
new = true
if options[:read]
  db.load(options[:read])
  new = false
elsif File.exists?(DEFAULT_DB)
  db.load(DEFAULT_DB)
  new = false
end

if ARGV.empty?
  db.add_dirs(['.']) if new
else
  db.add_dirs(ARGV)
end

# Update it
db.update if options[:auto] and not new

# Write it
if options[:auto] || options[:write]
  db.save(options[:write] || DEFAULT_DB)
end

if options[:query]
  table, value = options[:query].split(',', 2)
  db.query(table.to_sym, value)
end

if options[:summary]
  db.print_summary
end

if options[:dump]
  if options[:dump].is_a? String
    db.dump_table(options[:dump].to_sym)
  else
    db.dump_all
  end
end
