require 'redis'
require 'connection_pool'

module Readthis
  class Cache
    attr_reader :expires_in, :namespace, :pool

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
      with do |store|
        store.get(namespaced_key(key, merged_options(options)))
      end
    end

    def write(key, value, options = {})
      options    = merged_options(options)
      namespaced = namespaced_key(key, options)

      with do |store|
        if expiration = options[:expires_in]
          store.setex(namespaced, expiration, value)
        else
          store.set(namespaced, value)
        end
      end
    end

    def delete(key, options = {})
      with do |store|
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
      with do |store|
        store.incr(namespaced_key(key, merged_options(options)))
      end
    end

    def decrement(key, options = {})
      with do |store|
        store.decr(namespaced_key(key, merged_options(options)))
      end
    end

    def read_multi(*keys)
      options = merged_options(extract_options!(keys))
      results = []

      with do |store|
        results = store.pipelined do
          keys.each { |key| store.get(namespaced_key(key, options)) }
        end
      end

      keys.zip(results).to_h
    end

    # This must be done in two separate blocks. Redis pipelines return
    # futures, which can not be resolved until the pipeline has exited.
    def fetch_multi(*keys)
      results = read_multi(*keys)
      options = merged_options(extract_options!(keys))

      with do |store|
        store.pipelined do
          results.each do |key, value|
            if value.nil?
              value = yield key
              write(key, value, options)
              results[key] = value
            end
          end
        end
      end

      results
    end

    def exist?(key, options = {})
      with do |store|
        store.exists(namespaced_key(key, merged_options(options)))
      end
    end

    def clear
      with do |store|
        store.flushdb
      end
    end

    private

    def with(&block)
      pool.with(&block)
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
      namespace = options[:namespace]

      [namespace, key].compact.join(':')
    end
  end
end
