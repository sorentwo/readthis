require 'bundler'

Bundler.setup

require 'benchmark/ips'
require 'redis-activesupport'
require 'readthis'

url      = 'redis://localhost:6379/11'
readthis = Readthis::Cache.new(url, namespace: 'rd', expires_in: 60)
redisas  = ActiveSupport::Cache::RedisStore.new(url + '/ra')

('a'..'z').each do |key|
  readthis.write(key, key * 1024)
  redisas.write(key, key * 1024)
end

Benchmark.ips do |x|
  x.report 'readthis:read-multi' do
    readthis.read_multi(*('a'..'z'))
  end

  x.report 'redisas:read-multi' do
    redisas.read_multi(*('a'..'z'))
  end

  x.compare!
end

Benchmark.ips do |x|
  x.report 'readthis:fetch-multi' do
    readthis.fetch_multi(*('a'..'z')) { |_| 'missing' }
  end

  x.report 'redisas:fetch-multi' do
    redisas.fetch_multi(*('a'..'z')) { |_| 'missing' }
  end

  x.compare!
end
