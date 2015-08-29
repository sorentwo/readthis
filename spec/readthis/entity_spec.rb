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

    it 'applies compression when enabled' do
      string = 'a very large string, huge I tell you'
      entity = Readthis::Entity.new(compress: true, threshold: 8)
      dumped = Marshal.dump(string)

      expect(entity.dump(string)).not_to eq(dumped)
    end

    it 'does not dump nil values' do
      entity = Readthis::Entity.new

      expect(entity.dump(nil)).to be_nil
    end
  end

  describe '#load' do
    it 'unmarshals a value' do
      object = { a: 1, b: '2' }
      dumped = Marshal.dump(object)
      entity = Readthis::Entity.new

      expect(entity.load(dumped)).to eq(object)
    end

    it 'uncompresses when compression is enabled' do
      string = 'another one of those huge strings'
      entity = Readthis::Entity.new(compress: true, threshold: 0)
      dumped = Marshal.dump(string)

      compressed = entity.compress(dumped)

      expect(entity.load(compressed)).not_to eq(string)
    end

    it 'does not fail when compressed data size is below threshold' do
      # This string has very little entropy thus compression ratio is huge
      string = 'a' * 200
      entity = Readthis::Entity.new(compress: true, threshold: 50)
      # Store and reload the entity will not return the same value
      # when compressed length is below threshold
      expect(entity.load(entity.dump(string))).to eq string
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
