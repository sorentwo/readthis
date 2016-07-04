RSpec.describe Readthis::Serializers do
  CustomSerializer  = Class.new
  AnotherSerializer = Class.new

  describe '#<<' do
    it 'appends new serializers' do
      serializers = Readthis::Serializers.new

      serializers << CustomSerializer

      expect(serializers.marshals).to include(CustomSerializer)
      expect(serializers.flags).to eq([1, 2, 3, 4])
    end

    it 'increments flags' do
      serializers = Readthis::Serializers.new
      serializers << CustomSerializer
      serializers << AnotherSerializer

      expect(serializers.flags).to eq((1..5).to_a)
    end

    it 'prevents more than seven serializers' do
      serializers = Readthis::Serializers.new
      serializers << Class.new until serializers.flags.length >= 7
      expect do
        serializers << Class.new
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
    let(:serializers) { Readthis::Serializers.new }

    it 'inverts the current set of serializers' do
      expect(serializers.rassoc(1)).to eq(Marshal)
    end

    it 'returns custom serializers' do
      serializers << CustomSerializer
      expect(serializers.rassoc(4)).to eq(CustomSerializer)
    end

    it 'inverts default serializers after adding custom one' do
      serializers << CustomSerializer
      expect(serializers.rassoc(1)).to eq(Marshal)
      expect(serializers.rassoc(3)).to eq(JSON)
    end

    it 'takes into account only first 3 bytes of passed integer' do
      expect(serializers.rassoc(1)).to eq(Marshal)
      expect(serializers.rassoc(11)).to eq(JSON)
      serializers << CustomSerializer
      expect(serializers.rassoc(12)).to eq(CustomSerializer)
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

      expect(serializers.serializers.length).to eq(3)
    end
  end
end
