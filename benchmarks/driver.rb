require 'bundler'

Bundler.setup

require 'benchmark/ips'
require 'readthis'

native  = Readthis::Cache.new(redis: { driver: :ruby }, expires_in: 60)
hiredis = Readthis::Cache.new(redis: { driver: :hiredis }, expires_in: 60)

('a'..'z').each { |key| native.write(key, key * 1024) }

Benchmark.ips do |x|
  x.report('native:read-multi')  { native.read_multi(*('a'..'z')) }
  x.report('hiredis:read-multi') { hiredis.read_multi(*('a'..'z')) }

  x.compare!
end
