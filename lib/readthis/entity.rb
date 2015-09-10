require 'json'
require 'zlib'
require 'readthis/passthrough'

module Readthis
  class Entity
    DEFAULT_OPTIONS = {
      compress:  false,
      marshal:   Marshal,
      threshold: 8 * 1024
    }.freeze

    SERIALIZER_FLAGS = {
      Marshal     => 0x1,
      JSON        => 0x2,
      Passthrough => 0x3
    }.freeze

    DESERIALIZER_FLAGS = SERIALIZER_FLAGS.invert.freeze
    COMPRESSED_FLAG    = 0x8
    MARSHAL_FLAG       = 0x3

    def initialize(options = {})
      @options = DEFAULT_OPTIONS.merge(options)
    end

    def dump(value, options = {})
      marshal   = with_fallback(options, :marshal)
      threshold = with_fallback(options, :threshold)
      compress  = with_fallback(options, :compress)

      dumped = deflate(marshal.dump(value), compress, threshold)

      compose(dumped, marshal, compress)
    end

    def load(string)
      marshal, compress, value = decompose(string)

      marshal.load(inflate(value, compress))
    rescue TypeError, NoMethodError
      string
    end

    # Composes a single byte comprised of the chosen serializer and compression
    # options. The byte is formatted as:
    #
    # | 0000 | 0 | 000 |
    #
    # Where there are four unused bits, 1 compression bit, and 3 bits for the
    # serializer. This allows up to 8 different serializers for marshaling.
    def compose(value, marshal, compress)
      flags  = SERIALIZER_FLAGS[marshal]
      flags |= COMPRESSED_FLAG if compress

      value.prepend([flags].pack('C'))
    end

    def decompose(string)
      flags = string[0].unpack('C').first

      if flags < 16
        marshal  = DESERIALIZER_FLAGS[flags & MARSHAL_FLAG]
        compress = (flags & COMPRESSED_FLAG) != 0

        [marshal, compress, string[1..-1]]
      else
        [@options[:marshal], @options[:compress], string]
      end
    end

    private

    def deflate(value, compress, threshold)
      if compress && value.bytesize >= threshold
        Zlib::Deflate.deflate(value)
      else
        value
      end
    end

    def inflate(value, decompress)
      if decompress
        Zlib::Inflate.inflate(value)
      else
        value
      end
    rescue Zlib::Error
      value
    end

    def with_fallback(options, key)
      options.key?(key) ? options[key] : @options[key]
    end
  end
end
