#!/usr/bin/env ruby

lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'optparse'
require "starscope"

options = {auto: true}
DEFAULT_DB=".starscope.db"

# Options Parsing
OptionParser.new do |opts|
  opts.banner = <<END
Usage: starscope.rb [options] [PATHS]

If you don't pass any of -n, -r, -w or PATHS the default behaviour is to recurse
in the current directory and build or update the database `#{DEFAULT_DB}`.

Query scopes must be specified with `::`, for example -q calls,File::mtime.
END

  opts.separator "\nQueries"
  opts.on("-d", "--dump [TABLE]", "Dumps the DB or specified table to stdout") do |tbl|
    options[:dump] = tbl || true
  end
  opts.on("-l", "--line-mode", "Starts line-oriented interface") do
    options[:linemode] = true
  end
  opts.on("-q", "--query TABLE,QUERY", "Looks up QUERY in TABLE") do |query|
    options[:query] = query
  end
  opts.on("-s", "--summary", "Print a database summary to stdout") do
    options[:summary] = true
  end

  opts.separator "\nDatabase Management"
  opts.on("-n", "--no-auto", "Don't automatically update/create the database") do
    options[:auto] = false
  end
  opts.on("-r", "--read-db PATH", "Reads the DB from PATH instead of the default") do |path|
    options[:read] = path
  end
  opts.on("-w", "--write-db PATH", "Writes the DB to PATH instead of the default") do |path|
    options[:write] = path
  end

  opts.separator "\nMisc"
  opts.on("-v", "--version", "Print the version number") do
    puts StarScope::VERSION
    exit
  end

end.parse!

def print_summary(db)
  db.summary.each do |name, count|
    printf("%-8s %5d keys\n", name, count)
  end
end

def run_query(db, input, separator)
  table, value = input.split(separator, 2)
  if not value
    puts "Invalid query - did you separate your table and query with '#{separator}'?"
    return
  end
  puts db.query(table.to_sym, value)
rescue StarScope::DB::NoTableError
  puts "Table '#{table}' doesn't exist."
end

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
  run_query(db, options[:query], ',')
end

if options[:summary]
  print_summary(db)
end

if options[:dump]
  if options[:dump].is_a? String
    db.dump_table(options[:dump].to_sym)
  else
    db.dump_all
  end
end

if options[:linemode]
  puts <<END
Normal input is of the form
  table query
and returns the result of that query. The following special commands
are also recognized:
  !summary
  !update
  !quit

END
  while true
    print "> "
    input = gets.chomp
    case input
    when "!summary"
      print_summary(db)
    when "!update"
      db.update
      if options[:auto] || options[:write]
        db.save(options[:write] || DEFAULT_DB)
      end
    when "!quit"
      exit
    else
      run_query(db, input, ' ')
    end
  end
end
