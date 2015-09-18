require 'benchmark/ips'
require 'dalli'
require 'redis-activesupport'
require 'active_support/cache/memory_store'
require 'active_support/cache/dalli_store'
require 'readthis'

memory   = ActiveSupport::Cache::MemoryStore.new(expires_in: 60, namespace: 'mm')
dalli    = ActiveSupport::Cache::DalliStore.new('localhost', namespace: 'da', pool_size: 5, expires_in: 60)
redisas  = ActiveSupport::Cache::RedisStore.new('redis://localhost:6379/11/ra', expires_in: 60)
readthis = Readthis::Cache.new(namespace: 'rd', expires_in: 60)

('a'..'z').each do |key|
  value = key * 1024

  memory.write(key, value)
  dalli.write(key, value)
  readthis.write(key, value)
  redisas.write(key, value)
end

Benchmark.ips do |x|
  x.report 'memory:read-multi' do
    memory.read_multi(*('a'..'z'))
  end

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
  x.report 'memory:fetch-multi' do
    memory.fetch_multi(*('a'..'z')) { |_| 'missing' }
  end

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
