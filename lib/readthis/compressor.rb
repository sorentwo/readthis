require 'zlib'

module Readthis
  class Compressor
    attr_reader :threshold

    # Create a new Readthis::Compressor object that pivots on the provided
    # threshold value.
    #
    # @param threshold [Number] the threshold size required for compression
    def initialize(threshold: 1024)
      @threshold = threshold
    end

    # Compress a value if its size is greater or equal to the current threshold.
    #
    # @param value [String] a string to compress
    def compress(value)
      if value.size >= threshold
        Zlib::Deflate.deflate(value)
      else
        value
      end
    end

    # Decompress a previously compressed object. It will attempt to decode a
    # value regardless of whether it has been compressed, but will rescue
    # decoding errors.
    #
    # @param value [String] a possibly compressed string to decompress
    def decompress(value)
      if value.size >= threshold
        Zlib::Inflate.inflate(value)
      else
        value
      end
    rescue Zlib::Error
      value
    end
  end
end
