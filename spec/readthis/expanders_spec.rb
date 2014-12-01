require 'readthis/expanders'

RSpec.describe Readthis::Expanders do
  def expand(key, namespace = nil)
    Readthis::Expanders.expand(key, namespace)
  end

  describe '#expand' do
    it 'namespaces a plain string' do
      expect(expand('thing', 'space')).to eq('space/thing')
    end

    it 'expands an object that has a cache_key method' do
      object = double(cache_key: 'custom-key')

      expect(expand(object)).to eq('custom-key')
    end

    it 'expands an array of objects' do
      object = double(cache_key: 'gamma')

      expect(expand(['alpha', 'beta'])).to eq('alpha/beta')
      expect(expand([object, object])).to eq('gamma/gamma')
    end
  end
end
