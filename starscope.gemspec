require File.expand_path('../lib/starscope/version.rb', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'starscope'
  gem.version       = Starscope::VERSION
  gem.summary       = 'Smart code search and indexing'
  gem.description   = <<-EOF
  Starscope is a code indexer, search and navigation tool for Ruby, Golang, and JavaScript.
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
  gem.required_ruby_version = '>= 1.9.3'

  gem.add_dependency 'oj', '~> 2.9'
  gem.add_dependency 'parser', '>= 2.2.2'
  gem.add_dependency 'ruby-progressbar', '~> 1.5'
  gem.add_dependency 'rkelly-remix', '~> 0.0.7'
  gem.add_dependency 'babel-transpiler', '~> 0.7'
  gem.add_dependency 'sourcemap', '~> 0.1'

  gem.add_development_dependency 'bundler', '~> 1.7'
  gem.add_development_dependency 'rake', '~> 10.4'
  gem.add_development_dependency 'pry', '~> 0.10.1'
  gem.add_development_dependency 'minitest', '~> 5.8'
  gem.add_development_dependency 'mocha', '~> 1.1'
  gem.add_development_dependency 'rubocop', '~> 0.35.0'
end
