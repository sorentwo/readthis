require 'zlib'

module Readthis
  class Entity
    DEFAULT_OPTIONS = {
      compress:  false,
      marshal:   Marshal,
      threshold: 8 * 1024
    }.freeze

    MAGIC_BYTES = [120, 156].freeze

    def initialize(options = {})
      @options = DEFAULT_OPTIONS.merge(options)
    end

    def dump(value, options = {})
      marshal   = with_fallback(options, :marshal)
      threshold = with_fallback(options, :threshold)
      compress  = with_fallback(options, :compress)

      deflate(marshal.dump(value), compress, threshold)
    end

    def load(value, options = {})
      marshal  = with_fallback(options, :marshal)
      compress = with_fallback(options, :compress)

      marshal.load(inflate(value, compress))
    rescue TypeError
      value
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
      if decompress && value[0, 2].bytes == MAGIC_BYTES
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
