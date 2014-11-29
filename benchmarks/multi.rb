require 'bundler'

Bundler.setup

require 'benchmark/ips'
require 'dalli'
require 'redis-activesupport'
require 'active_support/cache/dalli_store'
require 'readthis'

redis_url = 'redis://localhost:6379/11'
dalli     = ActiveSupport::Cache::DalliStore.new('localhost', namespace: 'da', pool_size: 5)
redisas   = ActiveSupport::Cache::RedisStore.new(redis_url + '/ra')
readthis  = Readthis::Cache.new(redis_url, namespace: 'rd', expires_in: 60)

('a'..'z').each do |key|
  dalli.write(key, key * 1024)
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

  x.report 'dalli:read-multi' do
    dalli.read_multi(*('a'..'z'))
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

  x.report 'dalli:fetch-multi' do
    dalli.fetch_multi(*('a'..'z')) { |_| 'missing' }
  end

  x.compare!
end
