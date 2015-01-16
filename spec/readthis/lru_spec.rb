require 'readthis/lru'

RSpec.describe Readthis::LRU do
  describe '#set' do
    it 'adds a value to the cache' do
      lru = Readthis::LRU.new

      expect(lru.set('key', 'value')).to eq('value')
      expect(lru.get('key')).to eq('value')
    end

    it 'knocks old values out when the cache is full' do
      lru = Readthis::LRU.new(2)

      %w[a b c d].each do |key|
        lru.set(key, key)
      end

      expect(lru.count).to eq(2)
      expect(lru.to_a).to eq([['d', 'd'], ['c', 'c']])
    end
  end

  describe '#get' do
    it 'does not fetch expired entries' do
      lru = Readthis::LRU.new

      lru.set('key', 'value', 1)

      expect(lru.get('key')).to eq('value')
      sleep 1.1
      expect(lru.get('key')).to be_nil
      expect(lru.count).to be_zero
    end
  end

  describe '#mget' do
    it 'returns a collection keys mapped to values' do
      lru = Readthis::LRU.new
      lru.set('a', 'a')
      lru.set('b', 'b')
      lru.set('c', 'c')

      expect(lru.mget(['a', 'b', 'c', 'd'])).to eq(
        'a' => 'a',
        'b' => 'b',
        'c' => 'c',
        'd' => nil
      )
    end
  end

  describe '#mset' do
    it 'sets the values of a hash to the keys' do
      lru = Readthis::LRU.new
      lru.mset('a' => 1, 'b' => 2)

      expect(lru.get('a')).to eq(1)
      expect(lru.get('b')).to eq(2)
    end
  end

  describe '#exists?' do
    it 'is true when the value exists' do
      lru = Readthis::LRU.new

      expect(lru.exists?('key')).to be_falsey
      lru.set('key', 'value')
      expect(lru.exists?('key')).to be_truthy
    end
  end

  describe '#clear' do
    it 'clears all values from the cache' do
      lru = Readthis::LRU.new

      lru.set('key', 'value')
      lru.clear

      expect(lru.count).to be_zero
      expect(lru.to_a).to be_empty
    end
  end
end
