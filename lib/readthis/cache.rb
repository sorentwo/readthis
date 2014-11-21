# silence
# mute
# fetch_multi
#
# read_entry
# write_entry
# delete_entry

require 'redis'

module Readthis
  class Cache
    attr_reader :store

    # Creates a new Readthis::Cache object with the given redis URL. The URL
    # is parsed by the redis client directly.
    def initialize(url: )
      @store = Redis.new(url: url)
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
      value = read(key, options)

      if value.nil? && block_given?
        value = yield
        write(key, value, options)
      end

      value
    end

    def increment(key, options = {})
      store.incr(namespaced_key(key, options))
    end

    def decrement(key, options = {})
      store.decr(namespaced_key(key, options))
    end

    def read_multi(*keys)
      options = extract_options!(keys)

      results = store.pipelined do
        keys.each { |key| store.get(namespaced_key(key, options)) }
      end

      keys.zip(results).to_h
    end

    def exist?(key, options = {})
      store.exists(namespaced_key(key, options))
    end

    def clear
      store.flushall
    end

    # Supported for compatiblity, is simply a no-op
    def cleanup
    end

    protected

    def read_entry(key, options)
      store.get(namespaced_key(key, options))
    end

    def write_entry(key, value, options)
      namespaced = namespaced_key(key, options)

      store.set(namespaced, value)

      if expiration = options[:expires_in]
        store.expire(namespaced, expiration)
      end
    end

    def delete_entry(key, options)
      store.del(namespaced_key(key, options))
    end

    private

    def extract_options!(array)
      array.last.is_a?(Hash) ? array.pop : {}
    end

    def namespaced_key(key, options)
      namespace = options[:namespace]

      [namespace, key].compact.join(':')
    end
  end
end
