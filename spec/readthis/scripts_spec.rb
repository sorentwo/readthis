RSpec.describe Readthis::Scripts do
  let(:scripts) { Readthis::Scripts.new }

  describe '#run' do
    it 'raises an error with an unknown command' do
      expect do
        scripts.run('unknown', nil, [])
      end.to raise_error(Readthis::UnknownCommandError)
    end

    it 'runs the script command with a single key' do
      store = Redis.new

      store.set('alpha', 'content')
      scripts.run('mexpire', store, 'alpha', 1)

      expect(store.ttl('alpha')).to eq(1)
    end

    it 'runs the script command with multiple keys' do
      store = Redis.new

      store.set('beta', 'content')
      store.set('gamma', 'content')
      scripts.run('mexpire', store, %w[beta gamma], 1)

      expect(store.ttl('beta')).to eq(1)
      expect(store.ttl('gamma')).to eq(1)
    end
  end
end
