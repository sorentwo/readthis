# silence
# mute
# fetch_multi

require 'redis'

module Readthis
  class Cache
    attr_reader :expires_in, :namespace, :store

    # Creates a new Readthis::Cache object with the given redis URL. The URL
    # is parsed by the redis client directly.
    def initialize(url: , expires_in: nil, namespace: nil)
      @store      = Redis.new(url: url)
      @expires_in = expires_in
      @namespace  = namespace
    end

    def read(key, options = {})
      read_entry(key, options)
    end

    def write(key, value, options = {})
      write_entry(key, value, options)
    end

    def delete(key, options = {})
      delete_entry(key, options)
    end

    def fetch(key, options = {})
      value = read(key, options) unless options[:force]

      if value.nil? && block_given?
        value = yield
        write(key, value, options)
      end

      value
    end

    def increment(key, options = {})
      store.incr(namespaced_key(key, merged_options(options)))
    end

    def decrement(key, options = {})
      store.decr(namespaced_key(key, merged_options(options)))
    end

    def read_multi(*keys)
      options = merged_options(extract_options!(keys))

      results = store.pipelined do
        keys.each { |key| store.get(namespaced_key(key, options)) }
      end

      keys.zip(results).to_h
    end

    # This must be done in two separate blocks. Redis pipelines return
    # futures, which can not be resolved until the pipeline has exited.
    def fetch_multi(*keys)
      results = read_multi(*keys)
      options = merged_options(extract_options!(keys))

      store.pipelined do
        results.each do |key, value|
          if value.nil?
            value = yield key
            write_entry(key, value, options)
            results[key] = value
          end
        end
      end

      results
    end

    def exist?(key, options = {})
      store.exists(namespaced_key(key, merged_options(options)))
    end

    def clear
      store.flushall
    end

    # Supported for compatiblity, is simply a no-op
    def cleanup
    end

    protected

    def read_entry(key, options)
      store.get(namespaced_key(key, merged_options(options)))
    end

    def write_entry(key, value, options)
      options    = merged_options(options)
      namespaced = namespaced_key(key, options)

      store.set(namespaced, value)

      if expiration = options[:expires_in]
        store.expire(namespaced, expiration)
      end
    end

    def delete_entry(key, options)
      store.del(namespaced_key(key, merged_options(options)))
    end

    private

    def extract_options!(array)
      array.last.is_a?(Hash) ? array.pop : {}
    end

    def merged_options(options)
      options[:namespace]  ||= namespace
      options[:expires_in] ||= expires_in
      options
    end

    def namespaced_key(key, options)
      namespace = options[:namespace]

      [namespace, key].compact.join(':')
    end
  end
end
