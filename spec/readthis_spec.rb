require 'readthis'

RSpec.describe Readthis do
  describe '#serializers' do
    it 'lists currently configured serializers' do
      expect(Readthis.serializers.keys).to include(Marshal, JSON)
    end
  end
end
