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

      compose(dumped, marshal, compress)
    end

    def load(string)
      marshal, compress, value = decompose(string)

      marshal.load(inflate(value, compress))
    rescue TypeError
      string
    end

    def compose(value, marshal, compress)
      prefix = "|#{marshal.name}|#{compress}|#{MARKER_VERSION}|"

      value.prepend(prefix)
    end

    def decompose(marked)
      if marked[0] == '|'.freeze
        prefix = marked[0, 32][/\|(.*)\|/, 1]
        offset = prefix.size + 2

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
