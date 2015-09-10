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
      name   = marshal.name.ljust(24)
      comp   = compress ? '1'.freeze : '0'.freeze
      prefix = "R|#{name}#{comp}#{MARKER_VERSION}|R"

      value.prepend(prefix)
    end

    def decompose(marked)
      if marked && marked[0, 2] == 'R|'.freeze
        marshal  = Kernel.const_get(marked[2, 24].strip)
        compress = marked[27] == '1'.freeze

        [marshal, compress, marked[30..-1]]
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
