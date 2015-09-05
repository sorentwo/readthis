require 'zlib'

module Readthis
  class Entity
    MARKER_VERSION = '1'.freeze

    DEFAULT_OPTIONS = {
      compress:  false,
      marshal:   Marshal,
      threshold: 8 * 1024
    }.freeze

    def initialize(options = {})
      @options = DEFAULT_OPTIONS.merge(options)
    end

    def dump(value, options = {})
      marshal   = with_fallback(options, :marshal)
      threshold = with_fallback(options, :threshold)
      compress  = with_fallback(options, :compress)

      dumped = deflate(marshal.dump(value), compress, threshold)

      Readthis::Marker.compose(dumped, marshal, compress)
    end

    def load(string)
      marshal, compress, value = Readthis::Marker.decompose(string)

      marshal.load(inflate(value, compress))
    rescue TypeError
      string
    end

    def compose(value, marshal, compress)
      prefix = "RDS|#{marshal.name}|#{compress}|#{MARKER_VERSION}|RDS"

      value.prepend(prefix)
    end

    def decompose(marked)
      if marked[0, 3] == 'RDS'.freeze
        prefix = marked[0, 32][/RDS\|(.*)\|RDS/, 1]
        offset = prefix.size + 8

        m_name, c_name, _ = prefix.split('|'.freeze)

        marshal  = Kernel.const_get(m_name)
        compress = c_name == 'true'.freeze

        [marshal, compress, marked[offset..-1]]
      else
        [@options[:marshal], @options[:compress], marked]
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
