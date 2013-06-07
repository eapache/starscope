lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'starscope/version.rb'

Gem::Specification.new do |s|
  s.name          = 'starscope'
  s.version       = StarScope::VERSION
  s.date          = '2013-06-07'
  s.summary       = "A code indexer and analyzer"
  s.description   = "A tool like the venerable cscope, but for ruby and other languages"
  s.authors       = ["Evan Huus"]
  s.email         = 'evan.huus@jadedpixel.com'
  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'parser'
  s.add_development_dependency 'bundler', '~> 1.3'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'pry-debugger'
end
