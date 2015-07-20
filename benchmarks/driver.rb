require 'bundler'

Bundler.setup

require 'benchmark/ips'
require 'readthis'

REDIS_URL = 'redis://localhost:6379/11'
native  = Readthis::Cache.new(REDIS_URL, driver: :ruby,  expires_in: 60)
hiredis = Readthis::Cache.new(REDIS_URL, driver: :hiredis, expires_in: 60)

('a'..'z').each { |key| native.write(key, key * 1024) }

Benchmark.ips do |x|
  x.report('native:read-multi')  { native.read_multi(*('a'..'z')) }
  x.report('hiredis:read-multi') { hiredis.read_multi(*('a'..'z')) }

  x.compare!
end
