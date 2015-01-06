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
