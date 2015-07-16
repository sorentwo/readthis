require 'bundler'

Bundler.setup

require 'benchmark/ips'
require 'json'
require 'oj'
require 'readthis'
require 'readthis/passthrough'

REDIS_URL = 'redis://localhost:6379/11'
OPTIONS   = { compressed: false }

readthis_pass = Readthis::Cache.new(REDIS_URL, OPTIONS.merge(marshal: Readthis::Passthrough))
readthis_oj   = Readthis::Cache.new(REDIS_URL, OPTIONS.merge(marshal: Oj))
readthis_json = Readthis::Cache.new(REDIS_URL, OPTIONS.merge(marshal: JSON))
readthis_ruby = Readthis::Cache.new(REDIS_URL, OPTIONS.merge(marshal: Marshal))

HASH = ('a'..'z').each_with_object({}) { |key, memo| memo[key] = key }

Benchmark.ips do |x|
  x.report('pass:hash:dump') { readthis_pass.write('pass', HASH) }
  x.report('oj:hash:dump')   { readthis_oj.write('oj',     HASH) }
  x.report('json:hash:dump') { readthis_json.write('json', HASH) }
  x.report('ruby:hash:dump') { readthis_ruby.write('ruby', HASH) }

  x.compare!
end

Benchmark.ips do |x|
  x.report('pass:hash:load') { readthis_pass.read('pass') }
  x.report('oj:hash:load')   { readthis_oj.read('oj') }
  x.report('json:hash:load') { readthis_json.read('json') }
  x.report('ruby:hash:load') { readthis_ruby.read('ruby') }

  x.compare!
end
