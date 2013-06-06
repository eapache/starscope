# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'starscope/version'

Gem::Specification.new do |spec|
  spec.name          = "starscope"
  spec.version       = Starscope::VERSION
  spec.authors       = ["Evan Huus"]
  spec.email         = ["evan.huus@jadedpixel.com"]
  spec.description   = %q{Cscope for ruby and other languages.}
  spec.summary       = %q{Cscope-alike}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
