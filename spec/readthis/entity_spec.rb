require 'json'

RSpec.describe Readthis::Entity do
  describe '#dump' do
    it 'marshals the object as a ruby string' do
      string = 'some string'
      entity = Readthis::Entity.new

      expect(entity.dump(string)).to include(Marshal.dump(string))
    end

    it 'marshals using a custom marshaller' do
      string = 'some string'
      entity = Readthis::Entity.new(marshal: JSON)

      expect(entity.dump(string)).to include(JSON.dump(string))
    end

    it 'overrides the marshaller' do
      string = 'still some string'
      entity = Readthis::Entity.new

      expect(entity.dump(string, marshal: JSON)).to include(JSON.dump(string))
    end

    it 'applies compression when enabled' do
      string = 'a very large string, huge I tell you'
      entity = Readthis::Entity.new(compress: true, threshold: 8)
      dumped = Marshal.dump(string)

      expect(entity.dump(string)).not_to eq(dumped)
    end

    it 'does not return compressed data when the size is below threshold' do
      string = 'a' * 200
      entity = Readthis::Entity.new(compress: true, threshold: 50)

      expect(entity.load(entity.dump(string))).to eq(string)
    end

    it 'safely returns incorrectly deduced compressed data' do
      string = [120, 156, 97, 98, 99].pack('CCCCC')
      entity = Readthis::Entity.new(compress: true, threshold: 1)

      expect(entity.load(string)).to eq(string)
    end

    it 'overrides the compression threshold' do
      string = 'a' * 8
      entity = Readthis::Entity.new(compress: true, threshold: 2)
      dumped = entity.dump(string)

      expect(entity.dump(string, threshold: 100)).not_to eq(dumped)
    end

    it 'overrides the compression option' do
      string = 'a' * 8
      entity = Readthis::Entity.new(compress: true, threshold: 2)
      dumped = entity.dump(string)

      expect(entity.dump(string, compress: false)).not_to eq(dumped)
    end

    it 'safely roundtrips nil values' do
      entity = Readthis::Entity.new

      expect(entity.load(entity.dump(nil))).to be_nil
    end
  end

  describe '#load' do
    it 'unmarshals a value' do
      object = { a: 1, b: '2' }
      entity = Readthis::Entity.new
      dumped = entity.dump(object)

      expect(entity.load(dumped)).to eq(object)
    end

    it 'uncompresses when compression is enabled' do
      string = 'another one of those huge strings'
      entity = Readthis::Entity.new(compress: true, threshold: 4)
      dumped = entity.dump(dumped)

      expect(entity.load(dumped)).not_to eq(string)
    end

    it 'uses the dumped value to define load options' do
      value   = [1, 2, 3]
      custom  = Readthis::Entity.new(marshal: JSON, compress: true)
      general = Readthis::Entity.new(marshal: Marshal, compress: false)
      dumped  = custom.dump(value)

      expect(general.load(dumped)).to eq(value)
    end

    it 'passes through the value when it fails to marshal' do
      entity = Readthis::Entity.new

      expect { entity.load('not marshalled') }.not_to raise_error
    end

    it 'passes through the value when it fails to decompress' do
      entity = Readthis::Entity.new(compress: true, threshold: 0)
      dumped = Marshal.dump('some sizable string')

      expect { entity.load(dumped) }.not_to raise_error
    end
  end

  describe '#compose' do
    it 'prepends the string with a formatted marker' do
      string = 'the quick brown fox'
      marked = Readthis::Entity.new.compose(string, Marshal, true)

      expect(marked[0]).not_to eq('t')
    end
  end

  describe '#decompose' do
    it 'returns extracted options and values' do
      string = 'the quick brown fox'
      entity = Readthis::Entity.new
      marked = entity.compose(string.dup, JSON, true)

      marshal, compress, value = entity.decompose(marked)

      expect(marshal).to eq(JSON)
      expect(compress).to eq(true)
      expect(value).to eq(string)
    end

    it 'returns the original string without a marker' do
      string = 'the quick brown fox'
      entity = Readthis::Entity.new
      marshal, compress, value = entity.decompose(string)

      expect(marshal).to eq(Marshal)
      expect(compress).to eq(false)
      expect(value).to eq(string)
    end
  end
end
