module Readthis
  # Expander methods are used to transform an object into a string suitable for
  # use as a cache key.
  module Expanders
    # Expand an object into a suitable cache key.
    #
    # The behavior of `expand_key` is largely modeled on the `expand_cache_key`
    # method from `ActiveSupport::Cache`, with some subtle additions.
    #
    # @param [Object] key An object to stringify. Arrays, hashes, and objects
    #   that respond to either `cache_key` or `to_param` have direct support.
    #   All other objects will be coerced to a string, and frozen strings will
    #   be duplicated.
    #
    # @return [String] A cache key string.
    #
    # @example String expansion
    #
    #   Readthis::Expanders.expand_key('typical-key')
    #   'typical-key'
    #
    # @example Array string expansion
    #
    #   Readthis::Expanders.expand_key(['a', 'b', [:c, 'd'], 1])
    #   'a/b/c/d/1'
    #
    # @example Hash expansion
    #
    #   Readthis::Expanders.expand_key(c: 1, 'a' => 3, b: 2)
    #   'a=3/b=2/c=1'
    #
    def self.expand_key(key)
      case
      when key.is_a?(String)
        key.frozen? ? key.dup : key
      when key.is_a?(Array)
        key.flat_map { |elem| expand_key(elem) }.join('/')
      when key.is_a?(Hash)
        key
          .sort_by { |hkey, _| hkey.to_s }
          .map { |hkey, val| "#{hkey}=#{val}" }
          .join('/')
      when key.respond_to?(:cache_key)
        key.cache_key
      when key.respond_to?(:to_param)
        key.to_param
      else
        key.to_s
      end
    end

    # Prepend a namespace to a key after expanding it.
    #
    # @param [Object] key An object to stringify.
    # @param [String] namespace An optional namespace to prepend, if `nil` it
    #   is ignored.
    #
    # @return [String] A binary encoded string combining the namespace and key.
    #
    # @example Applying a namespace
    #
    #   Knuckles::Expanders.namespace_key('alpha', 'greek')
    #   'greek:alpha'
    #
    # @example Omitting a namespace
    #
    #   Knuckles::Expanders.namespace_key('alpha', nil)
    #   'alpha'
    #
    def self.namespace_key(key, namespace = nil)
      expanded = expand_key(key)

      if namespace
        "#{namespace}:#{expanded}"
      else
        expanded
      end.force_encoding(Encoding::BINARY)
    end
  end
end
