require 'readthis/entity'
require 'readthis/expanders'
require 'readthis/notifications'
require 'readthis/passthrough'
require 'redis'
require 'connection_pool'

module Readthis
  class Cache
    attr_reader :entity, :expires_in, :namespace, :options, :pool

    # Provide a class level lookup of the proper notifications module.
    # Instrumention is expected to occur within applications that have
    # ActiveSupport::Notifications available, but needs to work even when it
    # isn't.
    def self.notifications
      if defined?(ActiveSupport::Notifications)
        ActiveSupport::Notifications
      else
        Readthis::Notifications
      end
    end

    # Creates a new Readthis::Cache object with the given options.
    #
    # @option [Hash]    :redis Options that will be passed to the underlying redis connection
    # @option [Boolean] :compress (false) Enable or disable automatic compression
    # @option [Number]  :compression_threshold (8k) The size a string must be for compression
    # @option [Number]  :expires_in The number of seconds until an entry expires
    # @option [Module]  :marshal (Marshal) Any module that responds to `dump` and `load`
    # @option [String]  :namespace Prefix used to namespace entries
    # @option [Number]  :pool_size (5) The number of threads in the pool
    # @option [Number]  :pool_timeout (5) How long before a thread times out
    #
    # @example Create a new cache instance
    #   Readthis::Cache.new(namespace: 'cache', redis: { url: 'redis://localhost:6379/0' })
    #
    # @example Create a compressed cache instance
    #   Readthis::Cache.new(compress: true, compression_threshold: 2048)
    #
    def initialize(options = {})
      @options    = options
      @expires_in = options.fetch(:expires_in, nil)
      @namespace  = options.fetch(:namespace, nil)

      @entity = Readthis::Entity.new(
        marshal:   options.fetch(:marshal, Marshal),
        compress:  options.fetch(:compress, false),
        threshold: options.fetch(:compression_threshold, 1024)
      )

      @pool = ConnectionPool.new(pool_options(options)) do
        Redis.new(options.fetch(:redis, {}))
      end
    end

    # Fetches data from the cache, using the given key. If there is data in
    # the cache with the given key, then that data is returned. Otherwise, nil
    # is returned.
    #
    # @param [String] Key for lookup
    # @param [Hash] Optional overrides
    #
    # @example
    #
    #   cache.read('missing') # => nil
    #   cache.read('matched') # => 'some value'
    #
    def read(key, options = {})
      invoke(:read, key) do |store|
        value = store.get(namespaced_key(key, merged_options(options)))

        entity.load(value)
      end
    end

    # Writes data to the cache using the given key. Will overwrite whatever
    # value is already stored at that key.
    #
    # @param [String] Key for lookup
    # @param [Hash] Optional overrides
    #
    # @example
    #
    #   cache.write('some-key', 'a bunch of text')                     # => 'OK'
    #   cache.write('some-key', 'short lived', expires_in: 60)         # => 'OK'
    #   cache.write('some-key', 'lives elsehwere', namespace: 'cache') # => 'OK'
    #
    def write(key, value, options = {})
      options = merged_options(options)

      invoke(:write, key) do |store|
        write_entity(key, value, store, options)
      end
    end

    # Delete the value stored at the specified key. Returns `true` if
    # anything was deleted, `false` otherwise.
    #
    # @params [String] The key for lookup
    # @params [Hash] Optional overrides
    #
    # @example
    #
    #   cache.delete('existing-key') # => true
    #   cache.delete('random-key')   # => false
    def delete(key, options = {})
      namespaced = namespaced_key(key, merged_options(options))

      invoke(:delete, key) do |store|
        store.del(namespaced) > 0
      end
    end

    # Fetches data from the cache, using the given key. If there is data in the
    # cache with the given key, then that data is returned.
    #
    # If there is no such data in the cache (a cache miss), then `nil` will be
    # returned. However, if a block has been passed, that block will be passed
    # the key and executed in the event of a cache miss. The return value of
    # the block will be written to the cache under the given cache key, and
    # that return value will be returned.
    #
    # @param [String] Key for lookup
    # @param [Block] Optional block for generating the value when missing
    # @param options [Hash] Optional overrides
    # @option options [Boolean] :force Force a cache miss
    #
    # @example Typical
    #
    #   cache.write('today', 'Monday')
    #   cache.fetch('today') # => "Monday"
    #   cache.fetch('city')  # => nil
    #
    # @example With a block
    #
    #   cache.fetch('city') do
    #     'Duckburgh'
    #   end
    #   cache.fetch('city')   # => "Duckburgh"
    #
    # @example Cache Miss
    #
    #   cache.write('today', 'Monday')
    #   cache.fetch('today', force: true) # => nil
    #
    def fetch(key, options = {})
      value = read(key, options) unless options[:force]

      if value.nil? && block_given?
        value = yield(key)
        write(key, value, options)
      end

      value
    end

    # Increment a key in the store.
    #
    # If the key doesn't exist it will be initialized at 0. If the key exists
    # but it isn't a Fixnum it will be initialized at 0.
    #
    # @param [String] Key for lookup
    # @param [Fixnum] Value to increment by
    # @param [Hash] Optional overrides
    #
    # @example
    #
    #   cache.increment('counter') # => 0
    #   cache.increment('counter') # => 1
    #   cache.increment('counter', 2) # => 3
    #
    def increment(key, amount = 1, options = {})
      invoke(:incremenet, key) do |store|
        alter(key, amount, options)
      end
    end

    # Decrement a key in the store.
    #
    # If the key doesn't exist it will be initialized at 0. If the key exists
    # but it isn't a Fixnum it will be initialized at 0.
    #
    # @param [String] Key for lookup
    # @param [Fixnum] Value to decrement by
    # @param [Hash] Optional overrides
    #
    # @example
    #
    #   cache.write('counter', 20) # => 20
    #   cache.decrement('counter') # => 19
    #   cache.decrement('counter', 2) # => 17
    #
    def decrement(key, amount = 1, options = {})
      invoke(:decrement, key) do |store|
        alter(key, amount * -1, options)
      end
    end

    # Read multiple values at once from the cache. Options can be passed in the
    # last argument.
    #
    # @overload read_multi(keys)
    #   Return all values for the given keys.
    #   @param [String] One or more keys to fetch
    #
    # @return [Hash] A hash mapping keys to the values found.
    #
    # @example
    #
    #   cache.write('a', 1)
    #   cache.read_multi('a', 'b') # => { 'a' => 1, 'b' => nil }
    #
    def read_multi(*keys)
      options = merged_options(extract_options!(keys))
      mapping = keys.map { |key| namespaced_key(key, options) }

      return {} if keys.empty?

      invoke(:read_multi, keys) do |store|
        values = store.mget(mapping).map { |value| entity.load(value) }

        keys.zip(values).to_h
      end
    end

    # Write multiple key value pairs simultaneously. This is an atomic
    # operation that will always succeed and will overwrite existing
    # values.
    #
    # This is a non-standard, but useful, cache method.
    #
    # @param [Hash] Key value hash to write
    # @param [Hash] Optional overrides
    #
    # @example
    #
    #   cache.write_multi({ 'a' => 1, 'b' => 2 }) # => true
    #
    def write_multi(hash, options = {})
      options = merged_options(options)

      invoke(:write_multi, hash.keys) do |store|
        store.multi do
          hash.each { |key, value| write_entity(key, value, store, options) }
        end
      end
    end

    # Fetches multiple keys from the cache using a single call to the server
    # and filling in any cache misses. All read and write operations are
    # executed atomically.
    #
    # @overload fetch_multi(keys)
    #   Return all values for the given keys, applying the block to the key
    #   when a value is missing.
    #   @param [String] One or more keys to fetch
    #
    # @example
    #
    #   cache.fetch_multi('alpha', 'beta') do |key|
    #     "#{key}-was-missing"
    #   end
    #
    #   cache.fetch_multi('a', 'b', expires_in: 60) do |key|
    #     key * 2
    #   end
    #
    def fetch_multi(*keys)
      results   = read_multi(*keys)
      extracted = extract_options!(keys)
      missing   = {}

      invoke(:fetch_multi, keys) do |store|
        results.each do |key, value|
          if value.nil?
            value = yield(key)
            missing[key] = value
            results[key] = value
          end
        end
      end

      write_multi(missing, extracted) if missing.any?

      results
    end

    # Returns `true` if the cache contains an entry for the given key.
    #
    # @param [String] Key for lookup
    # @param [Hash] Optional overrides
    #
    # @example
    #
    #   cache.exist?('some-key') # => false
    #   cache.exist?('some-key', namespace: 'cache') # => true
    #
    def exist?(key, options = {})
      invoke(:exist?, key) do |store|
        store.exists(namespaced_key(key, merged_options(options)))
      end
    end

    # Clear the entire cache. This flushes the current database, no
    # globbing is applied.
    #
    # @param [Hash] Options, only present for compatibility.
    #
    # @example
    #
    #   cache.clear #=> 'OK'
    def clear(_options = nil)
      invoke(:clear, '*', &:flushdb)
    end

    protected

    def write_entity(key, value, store, options)
      namespaced = namespaced_key(key, options)
      dumped = entity.dump(value, options)

      if expiration = options[:expires_in]
        store.setex(namespaced, expiration.to_i, dumped)
      else
        store.set(namespaced, dumped)
      end
    end

    private

    def alter(key, amount, options)
      number = read(key, options)
      delta  = number.to_i + amount
      write(key, delta, options)
      delta
    end

    def instrument(operation, key)
      name    = "cache_#{operation}.active_support"
      payload = { key: key }

      self.class.notifications.instrument(name, payload) { yield(payload) }
    end

    def invoke(operation, key, &block)
      instrument(operation, key) do
        pool.with(&block)
      end
    end

    def extract_options!(array)
      array.last.is_a?(Hash) ? array.pop : {}
    end

    def merged_options(options)
      options = options || {}
      options[:namespace]  ||= namespace
      options[:expires_in] ||= expires_in
      options
    end

    def pool_options(options)
      { size:    options.fetch(:pool_size, 5),
        timeout: options.fetch(:pool_timeout, 5) }
    end

    def namespaced_key(key, options)
      Readthis::Expanders.namespace_key(key, options[:namespace])
    end
  end
end
