# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'readthis/version'

Gem::Specification.new do |spec|
  spec.name = 'readthis'
  spec.version = Readthis::VERSION
  spec.authors = ['Parker Selbert']
  spec.email = ['parker@sorentwo.com']
  spec.summary = 'Pooled active support compliant caching with redis'
  spec.homepage = 'https://github.com/sorentwo/readthis'
  spec.license = 'MIT'

  spec.files = `git ls-files -z readthis.gemspec lib script README.md LICENSE.txt`.split("\x0")
  spec.require_paths = ['lib']

  spec.add_dependency 'connection_pool', '~> 2.1'
  spec.add_dependency 'redis', '>= 3.0', '< 5.0'

  spec.add_development_dependency 'activesupport', '> 4.0'
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'hiredis', '~> 0.6'
  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'rspec', '~> 3.7'
end
