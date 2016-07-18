require 'matchers/redis_matchers'

RSpec.describe Readthis::Cache do
  include RedisMatchers

  let(:cache) { Readthis::Cache.new }

  after do
    cache.clear
  end

  describe '#initialize' do
    it 'makes options available' do
      cache = Readthis::Cache.new(namespace: 'cache', expires_in: 1)

      expect(cache.options).to eq(namespace: 'cache', expires_in: 1)
    end
  end

  describe '#pool' do
    it 'uses the passed redis configuration' do
      cache = Readthis::Cache.new(redis: { driver: :hiredis })

      cache.pool.with do |client|
        expect(client.client.driver).to be(Redis::Connection::Hiredis)
      end
    end
  end

  describe '#write' do
    it 'stores strings in the cache' do
      cache.write('some-key', 'some-value')

      expect(cache.read('some-key')).to eq('some-value')
    end

    it 'stores values within a namespace' do
      cache.write('some-key', 'some-value', namespace: 'cache')

      expect(cache.read('some-key')).to be_nil
      expect(cache.read('some-key', namespace: 'cache')).to eq('some-value')
    end

    it 'roundtrips values as their original type' do
      object = { a: 1, b: 2 }

      cache.write('obj-key', object)

      expect(cache.read('obj-key')).to eq(object)
    end

    it 'uses a custom expiration' do
      cache = Readthis::Cache.new(expires_in: 10)

      cache.write('some-key', 'some-value')
      cache.write('other-key', 'other-value', expires_in: 1)

      expect(cache.read('some-key')).not_to be_nil
      expect(cache.read('other-key')).not_to be_nil

      expect(cache).to have_ttl('some-key' => 10, 'other-key' => 1)
    end

    it 'rounds floats to a valid expiration value' do
      cache = Readthis::Cache.new

      cache.write('some-key', 'some-value', expires_in: 0.1)

      expect(cache).to have_ttl('some-key' => 1)
    end

    it 'expands non-string keys' do
      key_obj = double(cache_key: 'custom')

      cache.write(key_obj, 'some-value')

      expect(cache.read('custom')).to eq('some-value')
    end
  end

  describe '#read' do
    it 'gracefully handles nil options' do
      expect { cache.read('whatever', nil) }.not_to raise_error
    end

    it 'can refresh the expiration of an entity' do
      cache = Readthis::Cache.new(refresh: true)

      cache.write('some-key', 'some-value', expires_in: 1)

      cache.read('some-key', expires_in: 2)
      expect(cache).to have_ttl('some-key' => 2)

      cache.read('some-key', expires_in: 0.1)
      expect(cache).to have_ttl('some-key' => 1)
    end
  end

  describe 'serializers' do
    after do
      Readthis.serializers.reset!
    end

    it 'uses globally configured serializers' do
      custom = Class.new do
        def self.dump(value)
          value
        end

        def self.load(value)
          value
        end
      end

      Readthis.serializers << custom

      cache.write('customized', 'some value', marshal: custom)

      expect(cache.read('customized')).to eq('some value')
    end
  end

  describe 'compression' do
    it 'roundtrips entries when compression is enabled' do
      com_cache = Readthis::Cache.new(compress: true, compression_threshold: 8)
      raw_cache = Readthis::Cache.new
      value = 'enough text that it should be compressed'

      com_cache.write('compressed', value)

      expect(com_cache.read('compressed')).to eq(value)
      expect(raw_cache.read('compressed')).to eq(value)
    end

    it 'roundtrips entries with option overrides' do
      cache = Readthis::Cache.new(compress: false)
      value = 'enough text that it should be compressed'

      cache.write('comp-round', value, marshal: JSON, compress: true, threshold: 8)

      expect(cache.read('comp-round')).to eq(value)
    end

    it 'roundtrips bulk entries when compression is enabled' do
      cache = Readthis::Cache.new(compress: true, compression_threshold: 8)
      value = 'also enough text to compress'

      cache.write('comp-a', value)
      cache.write('comp-b', value)

      expect(cache.read_multi('comp-a', 'comp-b')).to eq(
        'comp-a' => value,
        'comp-b' => value
      )

      expect(cache.fetch_multi('comp-a', 'comp-b')).to eq(
        'comp-a' => value,
        'comp-b' => value
      )
    end
  end

  describe '#fetch' do
    it 'gets an existing value' do
      cache.write('great-key', 'great')
      expect(cache.fetch('great-key')).to eq('great')
    end

    it 'sets the value from the provided block' do
      value = 'value for you'
      cache.fetch('missing-key') { value }
      expect(cache.read('missing-key')).to eq(value)
    end

    it 'returns computed value when using passthrough marshalling' do
      cache = Readthis::Cache.new(marshal: Readthis::Passthrough)
      result = cache.fetch('missing-key') { 'value for you' }
      expect(result).to eq('value for you')
    end

    it 'does not set for a missing key without a block' do
      expect(cache.fetch('missing-key')).to be_nil
    end

    it 'forces a cache miss when `force` is passed' do
      cache.write('short-key', 'stuff')
      cache.fetch('short-key', force: true) { 'other stuff' }

      expect(cache.read('short-key')).to eq('other stuff')
    end

    it 'gets an existing value when `options` are passed as nil' do
      cache.write('great-key', 'great')
      expect(cache.fetch('great-key', nil)).to eq('great')
    end

    it 'serves computed content when the cache is down and tolerance is enabled' do
      Readthis.fault_tolerant = true

      allow(cache.pool).to receive(:with).and_raise(Redis::CannotConnectError)

      computed = cache.fetch('error-key') { 'computed' }

      expect(computed).to eq('computed')
    end
  end

  describe '#read_multi' do
    it 'maps multiple values to keys' do
      cache.write('a', 1)
      cache.write('b', 2)
      cache.write('c', '3')

      expect(cache.read_multi('a', 'b', 'c')).to eq(
        'a' => 1,
        'b' => 2,
        'c' => '3'
      )
    end

    it 'respects namespacing' do
      cache.write('d', 1, namespace: 'cache')
      cache.write('e', 2, namespace: 'cache')

      expect(cache.read_multi('d', 'e', namespace: 'cache')).to eq(
        'd' => 1,
        'e' => 2
      )
    end

    it 'returns {} with no keys' do
      expect(cache.read_multi(namespace: 'cache')).to eq({})
    end

    it 'refreshes each key that is read' do
      cache = Readthis::Cache.new(refresh: true)

      cache.write('a', 1, expires_in: 1)
      cache.write('b', 2, expires_in: 1)

      cache.read_multi('a', 'b', expires_in: 2)

      expect(cache).to have_ttl('a' => 2, 'b' => 2)
    end
  end

  describe '#write_multi' do
    it 'writes multiple key value pairs simultaneously' do
      response = cache.write_multi('a' => 1, 'b' => 2)

      expect(response).to be_truthy
      expect(cache.read('a')).to eq(1)
      expect(cache.read('b')).to eq(2)
    end

    it 'respects passed options' do
      cache.write_multi(
        { 'a' => 1, 'b' => 2 },
        namespace: 'multi',
        expires_in: 1
      )

      expect(cache.read('a')).to be_nil
      expect(cache.read('a', namespace: 'multi')).to eq(1)

      expect(cache).to have_ttl('multi:a' => 1)
    end
  end

  describe '#fetch_multi' do
    it 'reads multiple values, filling in missing keys from a block' do
      cache.write('a', 1)
      cache.write('c', 3)

      results = cache.fetch_multi('a', 'b', 'c') { |key| key + key }

      expect(results).to eq(
        'a' => 1,
        'b' => 'bb',
        'c' => 3
      )

      expect(cache.read('b')).to eq('bb')
    end

    it 'uses passed options' do
      cache.write('a', 1, namespace: 'alph')

      results = cache.fetch_multi('a', 'b', namespace: 'alph') { |key| key }

      expect(results).to eq(
        'a' => 1,
        'b' => 'b'
      )

      expect(cache.read('b')).to be_nil
      expect(cache.read('b', namespace: 'alph')).not_to be_nil
    end

    it 'return empty results without keys' do
      results = cache.fetch_multi(namespace: 'alph') { |key| key }
      expect(results).to eq({})
    end
  end

  describe '#exist?' do
    it 'is true when the key has been set' do
      cache.write('existing-key', 'stuff')
      expect(cache.exist?('existing-key')).to be_truthy
    end

    it 'is false when the key has not been set' do
      expect(cache.exist?('random-key')).to be_falsey
    end
  end

  describe '#delete' do
    it 'deletes an existing key' do
      cache.write('not-long', 'for this world')

      expect(cache.delete('not-long')).to be_truthy
      expect(cache.read('not-long')).to be_nil
    end

    it 'safely returns false if nothing is deleted' do
      expect(cache.delete('no-such-key')).to be_falsy
    end
  end

  describe '#delete_matched' do
    it 'deletes all matching keys' do
      cache.write('tomcat', 'cat')
      cache.write('wildcat', 'cat')
      cache.write('bobcat', 'cat')
      cache.write('cougar', 'cat')

      expect(cache.delete_matched('tomcat')).to eq(1)
      expect(cache.read('tomcat')).to be_nil
      expect(cache.read('bobcat')).not_to be_nil
      expect(cache.read('wildcat')).not_to be_nil

      expect(cache.delete_matched('*cat', count: 1)).to eq(2)
      expect(cache.read('wildcat')).to be_nil
      expect(cache.read('bobcat')).to be_nil

      expect(cache.delete_matched('*cat')).to eq(0)
    end

    it 'respects namespacing when matching keys' do
      cache.write('tomcat', 'cat', namespace: 'feral')

      expect(cache.delete_matched('tom*', namespace: 'feral')).to eq(1)
    end
  end

  describe '#increment' do
    it 'atomically increases the stored integer' do
      cache.write('counter', 10)
      expect(cache.increment('counter')).to eq(11)
      expect(cache.read('counter')).to eq(11)
    end

    it 'defaults a missing key to 1' do
      expect(cache.increment('unknown')).to eq(1)
    end
  end

  describe '#decrement' do
    it 'decrements a stored integer' do
      cache.write('counter', 20)
      expect(cache.decrement('counter')).to eq(19)
    end

    it 'defaults a missing key to -1' do
      expect(cache.decrement('unknown')).to eq(-1)
    end
  end

  describe 'instrumentation' do
    it 'instruments cache invokations' do
      require 'active_support/notifications'

      notes  = ActiveSupport::Notifications
      cache  = Readthis::Cache.new
      events = []

      notes.subscribe(/cache_*/) do |*args|
        events << ActiveSupport::Notifications::Event.new(*args)
      end

      cache.write('a', 'a')
      cache.read('a')

      expect(events.length).to eq(2)
      expect(events.map(&:name)).to eq %w[
        cache_write.active_support
        cache_read.active_support
      ]
    end
  end
end
