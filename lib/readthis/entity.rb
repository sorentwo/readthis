require 'zlib'

module Readthis
  class Entity
    DEFAULT_OPTIONS = {
      compress:  false,
      marshal:   Marshal,
      threshold: 8 * 1024
    }.freeze

    COMPRESSED_FLAG = 0x8
    MARSHAL_FLAG    = 0x3

    # Creates a Readthis::Entity with default options. Each option can be
    # overridden later when entities are being dumped.
    #
    # Options are sticky, meaning that whatever is used when dumping will
    # automatically be used again when loading, regardless of how current
    # options are set.
    #
    # @option [Boolean] :compress (false) Enable or disable automatic compression
    # @option [Module]  :marshal (Marshal) Any module that responds to `dump` and `load`
    # @option [Number]  :threshold (8k) The size a string must be for compression
    #
    def initialize(options = {})
      @options = DEFAULT_OPTIONS.merge(options)
    end

    # Output a value prepared for cache storage. Passed options will override
    # whatever has been specified for the instance.
    #
    # @param  [String] String to dump
    # @option [Boolean] :compress Enable or disable automatic compression
    # @option [Module]  :marshal Any module that responds to `dump` and `load`
    # @option [Number]  :threshold The size a string must be for compression
    # @return [String] The prepared, possibly compressed, string
    #
    # @example Dumping a value using defaults
    #
    #   entity.dump(string)
    #
    # @example Dumping a value with overrides
    #
    #   entity.dump(string, compress: false)
    #
    def dump(value, options = {})
      compress  = with_fallback(options, :compress)
      marshal   = with_fallback(options, :marshal)
      threshold = with_fallback(options, :threshold)

      dumped = deflate(marshal.dump(value), compress, threshold)

      compose(dumped, marshal, compress)
    end

    # Parse a dumped value using the embedded options.
    #
    # @param  [String] Option embedded string to load
    # @return [String] The original dumped string, restored
    #
    # @example
    #
    #   entity.load(dumped)
    #
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
    #
    # @param  [String] String to prefix with flags
    # @param  [Module] The marshal module to be used
    # @param  [Boolean] Flag determining whether the value is compressed
    # @return [String] The original string with a single byte prefixed
    #
    # @example Compose an option embedded string
    #
    #   entity.compose(string, Marshal, false) => 0x1  + string
    #   entity.compose(string, JSON, true)     => 0x10 + string
    #
    def compose(value, marshal, compress)
      flags  = serializers.assoc(marshal)
      flags |= COMPRESSED_FLAG if compress

      value.prepend([flags].pack('C'))
    end

    # Decompose an option embedded string into marshal, compression and value.
    #
    # @param  [String] Option embedded string to
    # @return [Array<Module, Boolean, String>] An array comprised of the
    #   marshal, compression flag, and the base string.
    #
    def decompose(string)
      flags = string[0].unpack('C').first

      if flags < 16
        marshal  = serializers.rassoc(flags & MARSHAL_FLAG)
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

    def serializers
      Readthis.serializers
    end

    def with_fallback(options, key)
      options.key?(key) ? options[key] : @options[key]
    end
  end
end
