require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*_test.rb']
end

RuboCop::RakeTask.new

desc 'Run tests and style checks'
task default: [:test, :rubocop]
