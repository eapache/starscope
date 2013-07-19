#!/usr/bin/env ruby

lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'optparse'
require 'readline'
require 'starscope'

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
  opts.on("-e", "--export FORMAT[,PATH]", "Export in FORMAT to PATH, see EXPORTING below") do |export|
    options[:export] = export
  end
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

  opts.separator <<END
\nEXPORTING
    At the moment only one export format is supported: 'ctags'. If you don't
    specify a path, the file is written to 'tags' in the current directory.
END

end.parse!

def print_summary(db)
  db.summary.each do |name, count|
    printf("%-8s %5d keys\n", name, count)
  end
end

def run_query(db, table, value)
  if not value
    $stderr.puts "Invalid input - no query found."
    return
  end
  puts db.query(table.to_sym, value)
  return true
rescue StarScope::DB::NoTableError
  $stderr.puts "Table '#{table}' doesn't exist."
  return false
end

def dump(db, table)
  if table
    db.dump_table(table.to_sym)
  else
    db.dump_all
  end
  return true
rescue StarScope::DB::NoTableError
  $stderr.puts "Table '#{table}' doesn't exist."
  return false
end

if options[:auto] and not options[:write]
  options[:write] = DEFAULT_DB
end

if File.exists?(DEFAULT_DB) and not options[:read]
  options[:read] = DEFAULT_DB
end

db = StarScope::DB.new

if options[:read]
  db.load(options[:read])
  db.add_dirs(ARGV)
elsif ARGV.empty?
  db.add_dirs(['.'])
else
  db.add_dirs(ARGV)
end

db.update if options[:read] and options[:auto]

db.save(options[:write]) if options[:write]

if options[:export]
  format, path = options[:export].split(',', 2)
  case format
  when 'ctags'
    db.export_ctags(path || 'tags')
  else
    puts "Unrecognized export format"
  end
end

if options[:query]
  table, query = options[:query].split(',', 2)
  run_query(db, table, query)
end

print_summary(db) if options[:summary]

if options[:dump]
  if options[:dump].is_a? String
    dump(db, options[:dump])
  else
    dump(db, nil)
  end
end

def linemode_help
  <<END
Input can be a query of the form 'TABLE QUERY' or a special command starting
with a '!'. Recognized special commands are:
  !dump [TABLE]
  !summary
  !update

  !help
  !version
  !quit
END
end

if options[:linemode]
  puts "Run your query as 'TABLE QUERY' or run '!help' for more information."
  while input = Readline.readline("> ", true)
    cmd, param = input.split(' ', 2)
    if cmd[0] == '!'
      case cmd[1..-1]
      when "dump"
        dump(db, param)
      when "summary"
        print_summary(db)
      when "update"
        db.update
        db.save(options[:write]) if options[:write]
      when "help"
        puts linemode_help
      when "version"
        puts StarScope::VERSION
      when "quit"
        exit
      else
        puts "Unknown command: '#{input}', try '!help'."
      end
    else
      success = run_query(db, cmd, param)
      puts "Try '!help'." unless success
    end
  end
end
