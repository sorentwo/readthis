require 'readthis/cache'

RSpec.describe Readthis::Cache do
  let(:cache) { Readthis::Cache.new }

  after do
    cache.clear
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
      sleep 1.1
      expect(cache.read('some-key')).to be_nil
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

  describe '#exist?' do
    it 'is true when the key has been set' do
      cache.write('existing-key', 'stuff')
      expect(cache.exist?('existing-key')).to be_truthy
    end

    it 'is false when the key has not been set' do
      expect(cache.exist?('random-key')).to be_falsey
    end
  end
end
