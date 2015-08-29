require 'bundler'

Bundler.setup

require 'benchmark/ips'
require 'dalli'
require 'active_support'
require 'active_support/cache/dalli_store'
require 'readthis'

dalli = ActiveSupport::Cache::DalliStore.new(
  'localhost',
  pool_size: 5,
  compressed: true,
  compression_threshold: 8
)

readthis  = Readthis::Cache.new(
  pool_size: 5,
  compressed: true,
  compression_threshold: 128
)

KEY  = 'key'
TEXT = <<-TEXT
  An abstract cache store class. There are multiple cache store implementations, each having its own additional features. See the classes under the ActiveSupport::Cache module, e.g. ActiveSupport::Cache::MemCacheStore. MemCacheStore is currently the most popular cache store for large production websites.
  Some implementations may not support all methods beyond the basic cache methods of fetch, write, read, exist?, and delete.
  ActiveSupport::Cache::Store can store any serializable Ruby object.
  cache = ActiveSupport::Cache::MemoryStore.new
  cache.read('city')   # => nil
  cache.write('city', "Duckburgh")
  cache.read('city')   # => "Duckburgh"
  Keys are always translated into Strings and are case sensitive. When an object is specified as a key and has a cache_key method defined, this method will be called to define the key. Otherwise, the to_param method will be called. Hashes and Arrays can also be used as keys. The elements will be delimited by slashes, and the elements within a Hash will be sorted by key so they are consistent.
  cache.read('city') == cache.read(:city)   # => true
  Nil values can be cached.
  If your cache is on a shared infrastructure, you can define a namespace for your cache entries. If a namespace is defined, it will be prefixed on to every key. The namespace can be either a static value or a Proc. If it is a Proc, it will be invoked when each key is evaluated so that you can use application logic to invalidate keys.
  cache.namespace = -> { @last_mod_time }  # Set the namespace to a variable
  @last_mod_time = Time.now  # Invalidate the entire cache by changing namespace
  Caches can also store values in a compressed format to save space and reduce time spent sending data. Since there is overhead, values must be large enough to warrant compression. To turn on compression either pass compress: true in the initializer or as an option to fetch or write. To specify the threshold at which to compress values, set the :compress_threshold option. The default threshold is 16K.
TEXT

puts 'Compressed Write/Read:'
Benchmark.ips do |x|
  x.report 'readthis:write/read' do
    readthis.write(KEY, TEXT)
    readthis.read(KEY)
  end

  x.report 'dalli:write/read' do
    dalli.write(KEY, TEXT)
    dalli.read(KEY)
  end

  x.compare!
end

puts 'Compressed Read Multi:'
MULTI_KEY = (1..30).to_a
MULTI_KEY.each do |key|
  readthis.write(key, TEXT)
  dalli.write(key, TEXT)
end

Benchmark.ips do |x|
  x.report 'readthis:read_multi' do
    readthis.read_multi(*MULTI_KEY)
  end

  x.report 'dalli:read_multi' do
    dalli.read_multi(*MULTI_KEY)
  end

  x.compare!
end
