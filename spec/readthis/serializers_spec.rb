require 'readthis/serializers'

RSpec.describe Readthis::Serializers do
  CustomSerializer  = Class.new
  AnotherSerializer = Class.new

  describe '#<<' do
    it 'appends new serializers' do
      serializers = Readthis::Serializers.new

      serializers << CustomSerializer

      expect(serializers.modules).to include(CustomSerializer)
      expect(serializers.flags).to eq((1..4).to_a)
      expect(serializers.serializers).to include(
        CustomSerializer => 4
      )
    end

    it 'increments flags' do
      serializers = Readthis::Serializers.new
      serializers << CustomSerializer
      serializers << AnotherSerializer

      expect(serializers.flags).to eq((1..5).to_a)
    end

    it 'prevents more than seven serializers' do
      serializers = Readthis::Serializers.new

      expect {
        10.times { serializers << Class.new }
      }.to raise_error(Readthis::SerializersLimitError)
    end
  end

  describe '#inverted' do
    it 'inverts the current set of serializers' do
      serializers = Readthis::Serializers.new

      expect(serializers.inverted).to include(
        1 => Marshal
      )
    end
  end

  describe '#freeze' do
    it 'does now allow appending after freeze' do
      serializers = Readthis::Serializers.new

      serializers.freeze!

      expect {
        serializers << CustomSerializer
      }.to raise_error(Readthis::SerializersFrozenError)
    end
  end
end
