require File.expand_path('../lib/starscope/version.rb', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'starscope'
  gem.version       = Starscope::VERSION
  gem.summary       = 'Smart code search and indexing'
  gem.description   = <<-EOF
  Starscope is a code indexer, search and navigation tool for Ruby and Go.
  Inspired by the extremely popular Ctags and Cscope utilities, Starscope can
  answer a lot of questions about a lot of code.
  EOF
  gem.authors       = ['Evan Huus']
  gem.homepage      = 'https://github.com/eapache/starscope'
  gem.email         = 'eapache@gmail.com'
  gem.license       = 'MIT'
  gem.files         = `git ls-files`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  gem.test_files    = `git ls-files -- test/*`.split("\n")
  gem.require_paths = ['lib']
  gem.required_ruby_version = '>= 1.8.7'

  gem.add_dependency 'oj', '~> 2.9'
  gem.add_dependency 'parser', '~> 2.2.2'
  gem.add_dependency 'ruby-progressbar', '~> 1.5'
  gem.add_dependency 'backports', '~> 3.6'
  gem.add_development_dependency 'bundler', '~> 1.5'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'mocha'
end
