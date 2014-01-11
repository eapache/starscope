require "bundler/gem_tasks"
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'lib/starscope'
  t.test_files = FileList['test/lib/test_*.rb']
end

desc "Run tests"
task :default => :test
