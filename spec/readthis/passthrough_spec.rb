RSpec.describe Readthis::Passthrough do
  describe '.load' do
    it 'passes through the provided value' do
      value = Object.new
      expect(Readthis::Passthrough.load(value)).to eq(value)
    end
  end

  describe '.dump' do
    it 'passes through the provided value' do
      value = Object.new
      expect(Readthis::Passthrough.dump(value)).to eq(value)
    end
  end
end
