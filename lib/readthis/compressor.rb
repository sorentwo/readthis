require 'zlib'

module Readthis
  class Compressor
    # Compress a value if its size is greater or equal to the current threshold.
    #
    # @param value [String] a string to compress
    def compress(value)
      Zlib::Deflate.deflate(value)
    end

    # Decompress a previously compressed object. It will attempt to decode a
    # value regardless of whether it has been compressed, but will rescue
    # decoding errors.
    #
    # @param value [String] a possibly compressed string to decompress
    def decompress(value)
      Zlib::Inflate.inflate(value)
    rescue Zlib::Error
      value
    end
  end
end
