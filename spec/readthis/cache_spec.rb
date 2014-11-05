require 'readthis/cache'

RSpec.describe Readthis::Cache do
  describe '#write' do
    let(:cache) { Readthis::Cache.new }

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
      sleep 1.5
      expect(cache.read('some-key')).to be_nil
    end
  end
end
