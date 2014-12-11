require 'readthis/entity'
require 'json'

RSpec.describe Readthis::Entity do
  describe '.dump' do
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
  end

  describe '.load' do
    it 'unmarshals a value' do
      object = { a: 1, b: '2' }
      dumped = Marshal.dump(object)
      entity = Readthis::Entity.new

      expect(entity.load(dumped)).to eq(object)
    end

    it 'uncompresses when compression is enabled' do
      string = 'another one of those huge strings'
      entity = Readthis::Entity.new(compress: true, threshold: 8)
      dumped = Marshal.dump(string)

      compressed = entity.compress(dumped)

      expect(entity.load(compressed)).not_to eq(string)
    end
  end
end
