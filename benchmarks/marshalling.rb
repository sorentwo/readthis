require 'bundler'

Bundler.setup

require 'oj'
require 'json'
require 'benchmark/ips'

ARRAY      = ('a'..'z').to_a
HASH       = ARRAY.each_with_object({}) { |key, memo| memo[key] = key }
JSON_HASH  = Oj.dump(HASH)
RUBY_HASH  = Marshal.dump(HASH)
JSON_ARRAY = Oj.dump(ARRAY)
RUBY_ARRAY = Marshal.dump(ARRAY)

Benchmark.ips do |x|
  x.report('oj:hash:dump')   { Oj.dump(HASH) }
  x.report('json:hash:dump') { JSON.dump(HASH) }
  x.report('ruby:hash:dump') { Marshal.dump(HASH) }

  x.compare!
end

Benchmark.ips do |x|
  x.report('oj:hash:load')   { Oj.load(JSON_HASH) }
  x.report('json:hash:load') { JSON.load(JSON_HASH) }
  x.report('ruby:hash:load') { Marshal.load(RUBY_HASH) }

  x.compare!
end

Benchmark.ips do |x|
  x.report('oj:array:dump')   { Oj.dump(JSON_ARRAY) }
  x.report('json:array:dump') { JSON.dump(JSON_ARRAY) }
  x.report('ruby:array:dump') { Marshal.dump(RUBY_ARRAY) }

  x.compare!
end

Benchmark.ips do |x|
  x.report('oj:array:load')   { Oj.load(JSON_ARRAY) }
  x.report('json:array:load') { JSON.load(JSON_ARRAY) }
  x.report('ruby:array:load') { Marshal.load(RUBY_ARRAY) }

  x.compare!
end
