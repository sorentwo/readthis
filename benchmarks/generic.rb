require 'benchmark/ips'
require 'json'
require 'readthis'

READTHIS = Readthis::Cache.new(
  expires_in: 120,
  marshal: JSON,
  compress: true
)

def write_key(key)
  READTHIS.write(key, key.to_s * 2048)
end

KEYS = (1..1_000).to_a
KEYS.each { |key| write_key(key) }

Benchmark.ips do |x|
  x.report 'readthis:write' do
    write_key(KEYS.sample)
  end

  x.report 'readthis:read' do
    READTHIS.read(KEYS.sample)
  end

  x.report 'readthis:read_multi' do
    READTHIS.read(KEYS.sample(30))
  end
end
