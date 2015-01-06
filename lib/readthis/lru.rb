# Least Recently Used cache inspired by lru_redux:
# https://github.com/SamSaffron/lru_redux
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

    # Get the value at `key`. Returns `nil` if nothing exists.
    #
    # @param [String] Key used for lookup
    #
    # @example
    #
    #   lru.get('fake') # => nil
    #   lru.get('real') # => 'real value'
    #
    def get(key)
      found = true
      value = data.delete(key) { found = false }

      if found
        data[key] = value
      end
    end

    # Set the given `key` to the provided `value`. This will bump the
    # value to the top of the cache, preventing it from being dropped
    # out.
    #
    # @param [String] Key used for lookup
    # @param [Object] Any object to store
    #
    # @example
    #
    #   lru.set('key', 'value') # => 'value'
    #
    def set(key, value)
      data.delete(key)
      data[key] = value
      data.delete(data.first[0]) if data.length > max

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
      data.to_a.reverse!
    end
  end
end
