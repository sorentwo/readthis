RSpec.describe Readthis::Passthrough do
  let(:value) { 'skywalker' }

  describe '.load' do
    it 'passes through the provided value' do
      expect(Readthis::Passthrough.load(value)).to eq(value)
    end
  end

  describe '.dump' do
    it 'passes through the provided value' do
      expect(Readthis::Passthrough.dump(value)).to eq(value)
      expect(Readthis::Passthrough.dump(value)).not_to be(value)
    end

    it 'stringifies all objects' do
      expect(Readthis::Passthrough.dump(1)).to eq('1')
      expect(Readthis::Passthrough.dump(1.0)).to eq('1.0')
      expect(Readthis::Passthrough.dump({})).to eq('{}')
    end
  end
end
