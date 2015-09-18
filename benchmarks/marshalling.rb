require 'bundler'

Bundler.setup

require 'benchmark/ips'
require 'json'
require 'oj'
require 'msgpack'
require 'readthis'
require 'readthis/passthrough'

Readthis.serializers << Oj
Readthis.serializers << MessagePack

readthis_oj      = Readthis::Cache.new(marshal: Oj)
readthis_msgpack = Readthis::Cache.new(marshal: MessagePack)
readthis_json    = Readthis::Cache.new(marshal: JSON)
readthis_ruby    = Readthis::Cache.new(marshal: Marshal)

HASH = ('a'..'z').each_with_object({}) { |key, memo| memo[key] = key }

Benchmark.ips do |x|
  x.report('oj:hash:dump')      { readthis_oj.write('oj',           HASH) }
  x.report('json:hash:dump')    { readthis_json.write('json',       HASH) }
  x.report('msgpack:hash:dump') { readthis_msgpack.write('msgpack', HASH) }
  x.report('ruby:hash:dump')    { readthis_ruby.write('ruby',       HASH) }

  x.compare!
end

Benchmark.ips do |x|
  x.report('oj:hash:load')      { readthis_oj.read('oj') }
  x.report('json:hash:load')    { readthis_json.read('json') }
  x.report('msgpack:hash:load') { readthis_msgpack.read('msgpack') }
  x.report('ruby:hash:load')    { readthis_ruby.read('ruby') }

  x.compare!
end
