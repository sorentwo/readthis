require 'readthis/entity'
require 'json'

RSpec.describe Readthis::Entity do
  describe '#dump' do
    it 'marshals the object as a ruby string' do
      string = 'some string'
      entity = Readthis::Entity.new

      expect(entity.dump(string)).to eq(Marshal.dump(string))
    end

    it 'marshals using a custom marshaller' do
      string = 'some string'
      entity = Readthis::Entity.new(marshal: JSON)

      expect(entity.dump(string)).to eq(JSON.dump(string))
    end

    it 'overrides the marshaller' do
      string = 'still some string'
      entity = Readthis::Entity.new

      expect(entity.dump(string, marshal: JSON)).to eq(JSON.dump(string))
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
      dumped = Marshal.dump(object)
      entity = Readthis::Entity.new

      expect(entity.load(dumped)).to eq(object)
    end

    it 'unmarshals with a custom marshaller per method call' do
      object = [1, 2, 3]
      dumped = JSON.dump(object)
      entity = Readthis::Entity.new

      expect(entity.load(dumped, marshal: JSON)).to eq(object)
    end

    it 'uncompresses when compression is enabled' do
      string = 'another one of those huge strings'
      entity = Readthis::Entity.new(compress: true, threshold: 4)
      dumped = entity.dump(dumped)

      expect(entity.load(dumped)).not_to eq(string)
    end

    it 'does not try to load a nil value' do
      entity = Readthis::Entity.new

      expect(entity.load(nil)).to be_nil
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
end
