require 'readthis/cache'

RSpec.describe Readthis::Cache do
  let(:url)   { 'redis://localhost:6379/11' }
  let(:cache) { Readthis::Cache.new(url) }

  after do
    cache.clear
  end

  describe '#initialize' do
    it 'accepts and persists a namespace' do
      cache = Readthis::Cache.new(url, namespace: 'kash')

      expect(cache.namespace).to eq('kash')
    end

    it 'accepts and persists an expiration' do
      cache = Readthis::Cache.new(url, expires_in: 10)

      expect(cache.expires_in).to eq(10)
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

    it 'uses a custom expiration' do
      cache.write('some-key', 'some-value', expires_in: 1)

      expect(cache.read('some-key')).not_to be_nil
      sleep 1.01
      expect(cache.read('some-key')).to be_nil
    end

    it 'expands non-string keys' do
      key_obj = double(cache_key: 'custom')

      cache.write(key_obj, 'some-value')

      expect(cache.read('custom')).to eq('some-value')
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

    it 'does not set for a missing key without a block' do
      expect(cache.fetch('missing-key')).to be_nil
    end

    it 'forces a cache miss when `force` is passed' do
      cache.write('short-key', 'stuff')
      cache.fetch('short-key', force: true) { 'other stuff' }

      expect(cache.read('short-key')).to eq('other stuff')
    end
  end

  describe '#read_multi' do
    it 'maps multiple values to keys' do
      cache.write('a', 1)
      cache.write('b', 2)
      cache.write('c', 3)

      expect(cache.read_multi('a', 'b', 'c')).to eq(
        'a' => '1',
        'b' => '2',
        'c' => '3',
      )
    end

    it 'respects namespacing' do
      cache.write('d', 1, namespace: 'cache')
      cache.write('e', 2, namespace: 'cache')

      expect(cache.read_multi('d', 'e', namespace: 'cache')).to eq(
        'd' => '1',
        'e' => '2',
      )
    end
  end

  describe '#fetch_multi' do
    it 'reads multiple values, filling in missing keys from a block' do
      cache.write('a', 1)
      cache.write('c', 3)

      results = cache.fetch_multi('a', 'b', 'c') { |key| key + key }

      expect(results).to eq(
        'a' => '1',
        'b' => 'bb',
        'c' => '3',
      )
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
      cache.delete('not-long')

      expect(cache.read('not-long')).to be_nil
    end
  end

  describe '#increment' do
    it 'atomically increases the stored integer' do
      cache.write('counter', 10)
      expect(cache.increment('counter')).to eq(11)
      expect(cache.read('counter')).to eq('11')
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
end
