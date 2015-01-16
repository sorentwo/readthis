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

    # Fetch multiple entries at once. Ruturns a key/value hash for the
    # given entries. Internally uses `get`, so entries are promoted or
    # expired as expected.
    #
    # @param [Array<String>] List of keys to retrieve
    #
    # @example
    #
    #   lru.mget(['a', 'b']) # => { 'a' => 1, 'b' => 2 }
    #
    def mget(keys)
      keys.each_with_object({}) do |key, memo|
        memo[key] = get(key)
      end
    end

    # Set multiple entries at once. There is no guarantee on what is
    # returned. Internally uses `set`, so all keys are promoted as
    # expected.
    #
    # @param [Hash] Hash of key/values to set
    #
    # @example
    #
    #   lru.mset('a' => 1, 'b' => 2) # => true
    #
    def mset(hash)
      hash.each do |key, value|
        set(key, value)
      end
    end

    # Set the given `key` to the provided `value`. This will bump the
    # value to the top of the cache, preventing it from being dropped
    # out.
    #
    # @param [String] Key used for lookup
    # @param [Object] Any object to store
    # @param [Number] An optional `ttl` value, in seconds
    #
    # @example
    #
    #   lru.set('key', 'value')       # => 'value'
    #   lru.setex('key', 'value', 3600) # => 'value'
    #
    def set(key, value, ttl = nil)
      data.delete(key)
      data[key] = [expiration(ttl), value]
      data.shift if data.length > max

      value
    end

    alias_method :setex, :set

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

    # Determine if a value exists. This uses `get` internally and will
    # bump the queried key to the top of the stack.
    #
    # @param [String] Key to check for existence
    #
    # @example
    #
    #   lru.exists?('some key') # => true
    #
    def exists?(key)
      !!get(key)
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
      if entry
        expiration = entry[0]
        expiration.nil? || expiration > Time.now.to_i
      end
    end
  end
end
