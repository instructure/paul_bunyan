# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'paul_bunyan/version'

Gem::Specification.new do |spec|
  spec.name          = 'paul_bunyan'
  spec.version       = PaulBunyan::VERSION
  spec.authors       = ['Duane Johnson', 'Kenneth Romney', 'Mark Severson', 'Tyler Pickett']
  spec.email         = ['duane@instructure.com', 'kromney@instructure.com', 'markse@instructure.com', 'tpickett@instructure.com']
  spec.summary       = 'Logging for all the things'
  spec.description   = "Extensions and enhancements to Ruby's built in Logger class. Extensions include: multiple output streams, JSON formatting for easy aggregation, and a Railtie to set some sane(ish) defaults for production Rails environments."
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'request_store'

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'wwtd'
  spec.add_development_dependency 'rails'
  spec.add_development_dependency 'sqlite3'
end
