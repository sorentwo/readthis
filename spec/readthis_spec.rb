RSpec.describe Readthis do
  describe '#serializers' do
    it 'lists currently configured serializers' do
      expect(Readthis.serializers.marshals).to include(Marshal, JSON)
    end
  end

  describe '#fault_tolerant?' do
    it 'defaults to being false' do
      expect(Readthis).not_to be_fault_tolerant
    end

    it 'can be enabled' do
      Readthis.fault_tolerant = true

      expect(Readthis).to be_fault_tolerant
    end
  end
end
