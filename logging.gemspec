# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'logging/version'

Gem::Specification.new do |spec|
  spec.name          = "logging"
  spec.version       = Logging::VERSION
  spec.authors       = ["Duane Johnson", "Tyler Pickett"]
  spec.email         = ["duane@instructure.com", "tpickett@instructure.com"]
  spec.summary       = %q{Logging for all the things}
  spec.description   = %q{Logging for all the things}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
