require 'benchmark/ips'
require 'readthis'

cache = Readthis::Cache.new(namespace: 'rd', expires_in: 60)
range = ('a'..'z').to_a

range.each { |key| cache.write(key, key) }

Benchmark.ips do |x|
  x.report 'read_multi:standard' do
    cache.read_multi(*range.sample(15))
  end

  x.report 'read_multi:refresh' do
    cache.read_multi(*range.sample(15), refresh: true)
  end

  x.compare!
end
