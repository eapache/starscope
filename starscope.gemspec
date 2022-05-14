require File.expand_path('lib/starscope/version.rb', __dir__)

Gem::Specification.new do |gem|
  gem.name          = 'starscope'
  gem.version       = Starscope::VERSION
  gem.summary       = 'Smart code search and indexing'
  gem.description   = <<-DESC
  Starscope is a code indexer, search and navigation tool for Ruby, Golang, and JavaScript.
  Inspired by the extremely popular Ctags and Cscope utilities, Starscope can
  answer a lot of questions about a lot of code.
  DESC
  gem.authors       = ['Evan Huus']
  gem.homepage      = 'https://github.com/eapache/starscope'
  gem.email         = 'eapache@gmail.com'
  gem.license       = 'MIT'
  gem.files         = `git ls-files`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  gem.test_files    = `git ls-files -- test/*`.split("\n")
  gem.require_paths = ['lib']
  gem.required_ruby_version = '>= 2.6'

  gem.add_dependency 'babel-transpiler', '~> 0.7'
  gem.add_dependency 'oj', '~> 3.7'
  gem.add_dependency 'parser', '~> 3.1'
  gem.add_dependency 'rkelly-remix', '~> 0.0.7'
  gem.add_dependency 'ruby-progressbar', '~> 1.9'
  gem.add_dependency 'sourcemap', '~> 0.1'

  gem.add_development_dependency 'bundler', '>= 1.7'
  gem.add_development_dependency 'byebug', '~> 11.1'
  gem.add_development_dependency 'minitest', '~> 5.12'
  gem.add_development_dependency 'mocha', '~> 1.3'
  gem.add_development_dependency 'rake', '~> 13.0'
  gem.add_development_dependency 'rubocop', '~> 1.25.0'
  gem.add_development_dependency 'rubocop-minitest', '~> 0.17.1'
  gem.add_development_dependency 'rubocop-rake', '~> 0.6.0'
  gem.metadata['rubygems_mfa_required'] = 'true'
end
