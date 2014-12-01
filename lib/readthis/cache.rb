require 'readthis/expanders'
require 'readthis/notifications'
require 'redis'
require 'connection_pool'

module Readthis
  class Cache
    attr_reader :expires_in, :namespace, :pool

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
    #   Readthis::Cache.new('redis://localhost:6379/0', namespace: 'cache')
    def initialize(url, options = {})
      @expires_in = options.fetch(:expires_in, nil)
      @namespace  = options.fetch(:namespace, nil)

      @pool = ConnectionPool.new(pool_options(options)) do
        Redis.new(url: url)
      end
    end

    def read(key, options = {})
      invoke(:read, key) do |store|
        store.get(namespaced_key(key, merged_options(options)))
      end
    end

    def write(key, value, options = {})
      options    = merged_options(options)
      namespaced = namespaced_key(key, options)

      invoke(:write, key) do |store|
        if expiration = options[:expires_in]
          store.setex(namespaced, expiration, value)
        else
          store.set(namespaced, value)
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

    def increment(key, options = {})
      invoke(:incremenet, key) do |store|
        store.incr(namespaced_key(key, merged_options(options)))
      end
    end

    def decrement(key, options = {})
      invoke(:decrement, key) do |store|
        store.decr(namespaced_key(key, merged_options(options)))
      end
    end

    def read_multi(*keys)
      options = merged_options(extract_options!(keys))
      mapping = keys.map { |key| namespaced_key(key, options) }

      invoke(:read_multi, keys) do |store|
        keys.zip(store.mget(mapping)).to_h
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
      options[:namespace]  ||= namespace
      options[:expires_in] ||= expires_in
      options
    end

    def pool_options(options)
      { size:    options.fetch(:pool_size, 5),
        timeout: options.fetch(:pool_timeout, 5) }
    end

    def namespaced_key(key, options)
      Readthis::Expanders.expand(key, options[:namespace])
    end
  end
end
