RSpec.describe Readthis::Expanders do
  def expand(key, namespace = nil)
    Readthis::Expanders.namespace_key(key, namespace)
  end

  describe '#expand' do
    it 'namespaces a plain string' do
      expect(expand('thing', 'space')).to eq('space:thing')
    end

    it 'expands an object that has a cache_key method' do
      object = double(cache_key: 'custom-key')

      expect(expand(object)).to eq('custom-key')
    end

    it 'expands an array of objects' do
      object = double(cache_key: 'gamma')

      expect(expand(%w[alpha beta])).to eq('alpha/beta')
      expect(expand([object, object])).to eq('gamma/gamma')
    end

    it 'expands the keys of a hash' do
      keyhash = { 'beta' => 2, alpha: 1 }

      expect(expand(keyhash)).to eq('alpha=1/beta=2')
    end

    it 'uses the to_param method if available' do
      object = double(to_param: 'thing')

      expect(expand(object)).to eq('thing')
    end
  end
end
