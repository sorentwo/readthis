require 'readthis/entity'
require 'readthis/expanders'
require 'readthis/notifications'
require 'readthis/passthrough'
require 'redis'
require 'hiredis'
require 'connection_pool'

module Readthis
  class Cache
    attr_reader :entity, :expires_in, :namespace, :pool

    # Provide a class level lookup of the proper notifications module.
    # Instrumention is expected to occur within applications that have
    # ActiveSupport::Notifications available, but needs to work even when it
    # isn't.
    def self.notifications
      if Object.const_defined?('ActiveSupport::Notifications')
        ActiveSupport::Notifications
      else
        Readthis::Notifications
      end
    end

    # Creates a new Readthis::Cache object with the given redis URL. The URL
    # is parsed by the redis client directly.
    #
    # @param [String] A redis compliant url with necessary connection details
    # @option [Boolean] :compress (false) Enable or disable automatic compression
    # @option [Number] :compression_threshold (8k) The size a string must be for compression
    # @option [Number] :expires_in The number of seconds until an entry expires
    # @option [Module] :marshal (Marshal) Any module that responds to `dump` and `load`
    # @option [String] :namespace Prefix used to namespace entries
    # @option [Number] :pool_size (5) The number of threads in the pool
    # @option [Number] :pool_timeout (5) How long before a thread times out
    #
    # @example Create a new cache instance
    #   Readthis::Cache.new('redis://localhost:6379/0', namespace: 'cache')
    #
    # @example Create a compressed cache instance
    #   Readthis::Cache.new('redis://localhost:6379/0', compress: true, compression_threshold: 2048)
    #
    def initialize(url, options = {})
      @expires_in = options.fetch(:expires_in, nil)
      @namespace  = options.fetch(:namespace,  nil)

      @entity = Readthis::Entity.new(
        marshal:   options.fetch(:marshal, Marshal),
        compress:  options.fetch(:compress, false),
        threshold: options.fetch(:compression_threshold, 1024)
      )

      @pool = ConnectionPool.new(pool_options(options)) do
        Redis.new(url: url, driver: :hiredis)
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

    def write(key, value, options = {})
      options    = merged_options(options)
      namespaced = namespaced_key(key, options)

      invoke(:write, key) do |store|
        if expiration = options[:expires_in]
          store.setex(namespaced, expiration, entity.dump(value))
        else
          store.set(namespaced, entity.dump(value))
        end
      end
    end

    def delete(key, options = {})
      invoke(:delete, key) do |store|
        store.del(namespaced_key(key, merged_options(options)))
      end
    end

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

    def read_multi(*keys)
      options = merged_options(extract_options!(keys))
      mapping = keys.map { |key| namespaced_key(key, options) }

      invoke(:read_multi, keys) do |store|
        values = store.mget(mapping).map { |value| entity.load(value) }

        keys.zip(values).to_h
      end
    end

    # Fetches multiple keys from the cache using a single call to the server
    # and filling in any cache misses. All read and write operations are
    # executed atomically.
    #
    #   cache.fetch_multi('alpha', 'beta') do |key|
    #     "#{key}-was-missing"
    #   end
    def fetch_multi(*keys)
      results = read_multi(*keys)
      options = merged_options(extract_options!(keys))

      invoke(:fetch_multi, keys) do |store|
        store.pipelined do
          results.each do |key, value|
            if value.nil?
              value = yield key
              write(key, value, options)
              results[key] = value
            end
          end
        end

        results
      end
    end

    def exist?(key, options = {})
      invoke(:exist?, key) do |store|
        store.exists(namespaced_key(key, merged_options(options)))
      end
    end

    def clear
      invoke(:clear, '*', &:flushdb)
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

      self.class.notifications.instrument(name, key) { yield(payload) }
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
