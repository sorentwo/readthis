require 'zlib'

module Readthis
  class Compressor
    attr_reader :minimum

    def initialize(minimum: 1024)
      @minimum = minimum
    end

    def compress(value)
      if value.size >= minimum
        Zlib::Deflate.deflate(value)
      else
        value
      end
    end

    def decompress(value)
      if value.size >= minimum
        Zlib::Inflate.inflate(value)
      else
        value
      end
    rescue Zlib::Error
      value
    end
  end
end
