require 'zlib'

module Readthis
  class Entity
    DEFAULT_THRESHOLD = 8 * 1024

    attr_reader :marshal, :compression, :threshold

    def initialize(marshal: Marshal, compress: false, threshold: DEFAULT_THRESHOLD)
      @marshal     = marshal
      @compression = compress
      @threshold   = threshold
    end

    def dump(value)
      return value if value.nil?

      if compress?(value)
        compress(value)
      else
        marshal.dump(value)
      end
    end

    def load(value)
      return value if value.nil?

      if compress?(value)
        decompress(value)
      else
        marshal.load(value)
      end
    rescue TypeError, Zlib::Error
      value
    end

    def compress(value)
      Zlib::Deflate.deflate(marshal.dump(value))
    end

    def decompress(value)
      marshal.load(Zlib::Inflate.inflate(value))
    end

    private

    def compress?(value)
      compression && value.bytesize >= threshold
    end
  end
end
