# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'readthis/version'

Gem::Specification.new do |spec|
  spec.name          = 'readthis'
  spec.version       = Readthis::VERSION
  spec.authors       = ['Parker Selbert']
  spec.email         = ['parker@sorentwo.com']
  spec.summary       = 'Performant active support compliant caching with redis'
  spec.description   = 'Performant active support compliant caching with redis'
  spec.homepage      = 'https://github.com/sorentwo/readthis'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^(spec)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'redis', '~> 3.0'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake',    '~> 10.0'
  spec.add_development_dependency 'rspec',   '~> 3.1'
end
