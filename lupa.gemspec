# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lupa/version'

Gem::Specification.new do |spec|
  spec.name          = "lupa"
  spec.version       = Lupa::VERSION
  spec.authors       = ["Ezequiel Delpero"]
  spec.email         = ["edelpero@gmail.com"]
  spec.summary       = %q{Search Filters using Object Oriented Design.}
  spec.description   = %q{Lupa lets you create simple, robust and scaleable search filters with ease using regular Ruby classes and object oriented design patterns.}
  spec.homepage      = "https://github.com/edelpero/lupa"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.5.1"
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
