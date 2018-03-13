# frozen_string_literal: true

require 'readthis/entity'
require 'readthis/expanders'
require 'readthis/passthrough'
require 'readthis/scripts'
require 'redis'
require 'connection_pool'

module Readthis
  # Readthis is a Redis backed cache client. It is a drop in replacement for
  # any `ActiveSupport` compliant cache Above all Readthis emphasizes
  # performance, simplicity, and explicitness.
  class Cache
    attr_reader :entity, :notifications, :options, :pool, :scripts

    # Provide a class level lookup of the proper notifications module.
    # Instrumention is expected to occur within applications that have
    # ActiveSupport::Notifications available, but needs to work even when it
    # isn't.
    def self.notifications
      ActiveSupport::Notifications if defined?(ActiveSupport::Notifications)
    end

    # Creates a new Readthis::Cache object with the given options.
    #
    # @option options [Hash] :redis Options that will be passed to the redis
    #   connection
    # @option options [Boolean] :compress (false) Enable or disable automatic
    #   compression
    # @option options [Number] :compression_threshold (8k) Minimum string size
    #   for compression
    # @option options [Number] :expires_in The number of seconds until an entry
    #   expires
    # @option options [Boolean] :refresh (false) Automatically refresh key
    #   expiration
    # @option options [Boolean] :retain_nils (false) Whether nil values should
    #   be included in read_multi output
    # @option options [Module] :marshal (Marshal) Module that responds to
    #   `dump` and `load`
    # @option options [String] :namespace Prefix used to namespace entries
    # @option options [Number] :pool_size (5) The number of threads in the pool
    # @option options [Number] :pool_timeout (5) How long before a thread times
    #   out
    #
    # @example Create a new cache instance
    #
    #   Readthis::Cache.new(namespace: 'cache',
    #                       redis: { url: 'redis://localhost:6379/0' })
    #
    # @example Create a compressed cache instance
    #
    #   Readthis::Cache.new(compress: true, compression_threshold: 2048)
    #
    def initialize(options = {})
      @options = options

      @entity = Readthis::Entity.new(
        marshal: options.fetch(:marshal, Marshal),
        compress: options.fetch(:compress, false),
        threshold: options.fetch(:compression_threshold, 1024)
      )

      @pool = ConnectionPool.new(pool_options(options)) do
        Redis.new(options.fetch(:redis, {}))
      end

      @scripts = Readthis::Scripts.new
    end

    # Fetches data from the cache, using the given key. If there is data in
    # the cache with the given key, then that data is returned. Otherwise, nil
    # is returned.
    #
    # @param [String] key Key for lookup
    # @param [Hash] options Optional overrides
    #
    # @example
    #
    #   cache.read('missing') # => nil
    #   cache.read('matched') # => 'some value'
    #
    def read(key, options = {})
      options = merged_options(options)

      invoke(:read, key) do |store|
        key = namespaced_key(key, options)

        refresh_entity(key, store, options)

        entity.load(store.get(key))
      end
    end

    # Writes data to the cache using the given key. Will overwrite whatever
    # value is already stored at that key.
    #
    # @param [String] key Key for lookup
    # @param [Hash] options Optional overrides
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
    # @param [String] key The key for lookup
    # @param [Hash] options Optional overrides
    #
    # @example
    #
    #   cache.delete('existing-key') # => true
    #   cache.delete('random-key')   # => false
    #
    def delete(key, options = {})
      namespaced = namespaced_key(key, merged_options(options))

      invoke(:delete, key) do |store|
        store.del(namespaced) > 0
      end
    end

    # Delete all values that match a given pattern. The pattern must be defined
    # using Redis compliant globs. The following examples are borrowed from the
    # `KEYS` documentation:
    #
    # * `h?llo` matches hello, hallo and hxllo
    # * `h*llo` matches hllo and heeeello
    # * `h[ae]llo` matches hello and hallo, but not hillo
    # * `h[^e]llo` matches hallo, hbllo, ... but not hello
    # * `h[a-b]llo` matches hallo and hbllo
    #
    # Note that `delete_matched` does *not* use the `KEYS` command, making it
    # safe for use in production.
    #
    # @param [String] pattern The glob pattern for matching keys
    # @option [String] :namespace Prepend a namespace to the pattern
    # @option [Number] :count Configure the number of keys deleted at once
    #
    # @example Delete all 'cat' keys
    #
    #   cache.delete_matched('*cats') #=> 47
    #   cache.delete_matched('*dogs') #=> 0
    #
    def delete_matched(pattern, options = {})
      namespaced = namespaced_key(pattern, merged_options(options))

      invoke(:delete, pattern) do |store|
        cursor = nil
        count = options.fetch(:count, 1000)
        deleted = 0

        until cursor == '0'
          cursor, matched = store.scan(cursor || 0, match: namespaced, count: count)

          if matched.any?
            store.del(*matched)
            deleted += matched.length
          end
        end

        deleted
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
    # @param [String] key Key for lookup
    # @param options [Hash] Optional overrides
    # @option options [Boolean] :force Force a cache miss
    # @yield [String] Gives a missing key to the block, which is used to
    #   generate the missing value
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
    #
    #   cache.fetch('city') # => "Duckburgh"
    #
    # @example Cache Miss
    #
    #   cache.write('today', 'Monday')
    #   cache.fetch('today', force: true) # => nil
    #
    def fetch(key, options = {})
      options ||= {}
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
    # but it isn't a Fixnum it will be coerced to 0.
    #
    # Note that this method does *not* use Redis' native `incr` or `incrby`
    # commands. Those commands only work with number-like strings, and are
    # incompatible with the encoded values Readthis writes to the store. The
    # behavior of `incrby` is preserved as much as possible, but incrementing
    # is not an atomic action. If multiple clients are incrementing the same
    # key there will be a "last write wins" race condition, causing incorrect
    # counts.
    #
    # If you absolutely require correct counts it is better to use the Redis
    # client directly.
    #
    # @param [String] key Key for lookup
    # @param [Fixnum] amount Value to increment by
    # @param [Hash] options Optional overrides
    #
    # @example
    #
    #   cache.increment('counter') # => 1
    #   cache.increment('counter', 2) # => 3
    #
    def increment(key, amount = 1, options = {})
      invoke(:increment, key) do |store|
        alter(store, key, amount, options)
      end
    end

    # Decrement a key in the store.
    #
    # If the key doesn't exist it will be initialized at 0. If the key exists
    # but it isn't a Fixnum it will be coerced to 0. Like `increment`, this
    # does not make use of the native `decr` or `decrby` commands.
    #
    # @param [String] key Key for lookup
    # @param [Fixnum] amount Value to decrement by
    # @param [Hash] options Optional overrides
    #
    # @example
    #
    #   cache.write('counter', 20) # => 20
    #   cache.decrement('counter') # => 19
    #   cache.decrement('counter', 2) # => 17
    #
    def decrement(key, amount = 1, options = {})
      invoke(:decrement, key) do |store|
        alter(store, key, -amount, options)
      end
    end

    # Efficiently read multiple values at once from the cache. Options can be
    # passed in the last argument.
    #
    # @overload read_multi(keys)
    #   Return all values for the given keys.
    #   @param [String] One or more keys to fetch
    #   @param [Hash] options Configuration to override
    #
    # @return [Hash] A hash mapping keys to the values found.
    #
    # @example
    #
    #   cache.read_multi('a', 'b') # => { 'a' => 1 }
    #   cache.read_multi('a', 'b', retain_nils: true) # => { 'a' => 1, 'b' => nil }
    #
    def read_multi(*keys)
      options = merged_options(extract_options!(keys))
      mapping = keys.map { |key| namespaced_key(key, options) }

      return {} if keys.empty?

      invoke(:read_multi, keys) do |store|
        values = store.mget(*mapping).map { |value| entity.load(value) }

        refresh_entity(mapping, store, options)

        zipped_results(keys, values, options)
      end
    end

    # Write multiple key value pairs simultaneously. This is an atomic
    # operation that will always succeed and will overwrite existing
    # values.
    #
    # This is a non-standard, but useful, cache method.
    #
    # @param [Hash] hash Key value hash to write
    # @param [Hash] options Optional overrides
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
      options = extract_options!(keys).merge(retain_nils: true)
      results = read_multi(*keys, options)
      missing = {}

      invoke(:fetch_multi, keys) do |_store|
        results.each do |key, value|
          next unless value.nil?

          value = yield(key)
          missing[key] = value
          results[key] = value
        end
      end

      write_multi(missing, options) if missing.any?

      results
    end

    # Returns `true` if the cache contains an entry for the given key.
    #
    # @param [String] key Key for lookup
    # @param [Hash] options Optional overrides
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

    # Clear the entire cache by flushing the current database.
    #
    # This flushes everything in the current database, with no globbing
    # applied. Data in other numbered databases will be preserved.
    #
    # @option options [Hash] :async Flush the database asynchronously, only
    #   supported in Redis 4.0+
    #
    # @example
    #
    #   cache.clear #=> 'OK'
    #   cache.clear(async: true) #=> 'OK'
    #
    def clear(options = {})
      invoke(:clear, '*') do |store|
        if options[:async]
          store.flushdb(async: true)
        else
          store.flushdb
        end
      end
    end

    protected

    def refresh_entity(keys, store, options)
      return unless options[:refresh] && options[:expires_in]

      expiration = coerce_expiration(options[:expires_in])

      scripts.run('mexpire', store, keys, expiration)
    end

    def write_entity(key, value, store, options)
      namespaced = namespaced_key(key, options)
      dumped = entity.dump(value, options)

      if (expiration = options[:expires_in])
        store.setex(namespaced, coerce_expiration(expiration), dumped)
      else
        store.set(namespaced, dumped)
      end
    end

    private

    def alter(store, key, amount, options)
      options = merged_options(options)
      namespaced = namespaced_key(key, options)

      loaded = entity.load(store.get(namespaced))
      change = loaded.to_i + amount
      dumped = entity.dump(change, options)
      expiration = fallback_expiration(store, namespaced, options)

      if expiration
        store.setex(namespaced, coerce_expiration(expiration), dumped)
      else
        store.set(namespaced, dumped)
      end

      change
    end

    def fallback_expiration(store, key, options)
      options.fetch(:expires_in) do
        ttl = store.ttl(key)

        ttl > 0 ? ttl : nil
      end
    end

    def coerce_expiration(expires_in)
      Float(expires_in).ceil
    end

    def instrument(name, key)
      if self.class.notifications
        name = "cache_#{name}.active_support"
        payload = { key: key, name: name }

        self.class.notifications.instrument(name, payload) { yield(payload) }
      else
        yield
      end
    end

    def invoke(operation, key, &block)
      instrument(operation, key) do
        pool.with(&block)
      end
    rescue Redis::BaseError, Errno::EADDRNOTAVAIL => error
      raise error unless Readthis.fault_tolerant?
    end

    def extract_options!(array)
      array.last.is_a?(Hash) ? array.pop : {}
    end

    def merged_options(options)
      @options.merge(options || {})
    end

    def zipped_results(keys, values, options)
      zipped = keys.zip(values)

      zipped.select! { |(_, value)| value } unless options[:retain_nils]

      zipped.to_h
    end

    def pool_options(options)
      { size: options.fetch(:pool_size, 5),
        timeout: options.fetch(:pool_timeout, 5) }
    end

    def namespaced_key(key, options)
      Readthis::Expanders.namespace_key(key, options[:namespace])
    end
  end
end
