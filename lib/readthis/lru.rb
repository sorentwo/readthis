# Least Recently Used cache that respects entry expiration.
#
# Original implementation inspired by SamSaffron/lru_redux
module Readthis
  class LRU
    DEFAULT_MAX = 1024

    attr_reader :max, :data

    # Creates a new Readthis::LRU object with the specified maximum
    # number of objects to retain.
    #
    # @param [Number] The maximum number of values to retain
    #
    def initialize(max = DEFAULT_MAX)
      @max  = max
      @data = {}
    end

    # Get the value at `key`. Returns `nil` if nothing exists or the entry has
    # expired. This method has the intended side effect of evicting expired
    # cache entries, it is *not* a pure accessor.
    #
    # @param [String] Key used for lookup
    #
    # @example
    #
    #   lru.get('fake')    # => nil
    #   lru.get('real')    # => 'real value'
    #   lru.get('expired') # => nil
    #
    def get(key)
      found  = true
      entry  = data.delete(key) { found = false }
      found &= fresh?(entry)

      if found
        data[key] = entry
        entry[1]
      end
    end

    # Set the given `key` to the provided `value`. This will bump the
    # value to the top of the cache, preventing it from being dropped
    # out.
    #
    # Entries will remain in the store even when expired
    #
    # @param [String] Key used for lookup
    # @param [Object] Any object to store
    # @param [Number] An optional `ttl` value, in seconds
    #
    # @example
    #
    #   lru.set('key', 'value')       # => 'value'
    #   lru.set('key', 'value', 3600) # => 'value'
    #
    def set(key, value, ttl = nil)
      data.delete(key)
      data[key] = [expiration(ttl), value]
      data.shift if data.length > max

      value
    end

    # Delete the key from the cache. Simply maps to the underlying hash.
    #
    # @param [String] Key to delete
    #
    # @example
    #
    #   lru.delete('fake') # => nil
    #   lru.delete('real') # => 'real value'
    #
    def delete(key)
      data.delete(key)
    end

    # Clear everything from the cache
    def clear
      data.clear
    end

    # Get a count of entries in the cache
    def count
      data.count
    end

    # Convert the data into a list of key/value pairs. The order is
    # reversed, presenting the most recently used entry first.
    #
    # @example
    #
    #   lru.set('a', 1)
    #   lru.set('b', 2)
    #   lru.to_a # => [['a', 1], ['b', 2]]
    #
    def to_a
      data.map { |(key, entry)| [key, entry[1]] }.reverse!
    end

    private

    def expiration(ttl)
      Time.now.to_i + ttl unless ttl.nil?
    end

    def fresh?(entry)
      expiration = entry[0]

      expiration.nil? || expiration > Time.now.to_i
    end
  end
end
