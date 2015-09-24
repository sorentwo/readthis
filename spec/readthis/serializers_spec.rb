require 'readthis/serializers'

RSpec.describe Readthis::Serializers do
  CustomSerializer  = Class.new
  AnotherSerializer = Class.new

  describe '#<<' do
    it 'appends new serializers' do
      serializers = Readthis::Serializers.new

      serializers << CustomSerializer

      expect(serializers.marshals).to include(CustomSerializer)
      expect(serializers.flags).to eq((1..4).to_a)
    end

    it 'increments flags' do
      serializers = Readthis::Serializers.new
      serializers << CustomSerializer
      serializers << AnotherSerializer

      expect(serializers.flags).to eq((1..5).to_a)
    end

    it 'prevents more than seven serializers' do
      serializers = Readthis::Serializers.new

      expect do
        10.times { serializers << Class.new }
      end.to raise_error(Readthis::SerializersLimitError)
    end
  end

  describe '#assoc' do
    it 'looks up serializers by module' do
      serializers = Readthis::Serializers.new

      expect(serializers.assoc(Marshal)).to eq(0x1)
    end

    it 'raises a helpful error when the serializer is unknown' do
      serializers = Readthis::Serializers.new

      expect do
        serializers.assoc(CustomSerializer)
      end.to raise_error(Readthis::UnknownSerializerError)
    end
  end

  describe '#rassoc' do
    it 'inverts the current set of serializers' do
      serializers = Readthis::Serializers.new

      expect(serializers.rassoc(1)).to eq(Marshal)
    end

    it 'raises a helpful error when the flag is unknown' do
      serializers = Readthis::Serializers.new

      expect do
        serializers.rassoc(5)
      end.to raise_error(Readthis::UnknownSerializerError)
    end
  end

  describe '#freeze!' do
    it 'does now allow appending after freeze' do
      serializers = Readthis::Serializers.new

      serializers.freeze!

      expect do
        serializers << CustomSerializer
      end.to raise_error(Readthis::SerializersFrozenError)
    end
  end

  describe '#reset!' do
    it 'reverts back to the original set of serializers' do
      serializers = Readthis::Serializers.new

      serializers << Class.new
      serializers.reset!

      expect(serializers.marshals.length).to eq(3)
    end
  end
end
