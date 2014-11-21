# silence
# mute
# read_multi
# fetch_multi
#
# delete_matched
# increment
# decrement
# cleanup
#
# read_entry
# write_entry
# delete_entry

require 'redis'

module Readthis
  class Cache
    attr_reader :store

    def initialize
      @store = Redis.new(url: 'redis://localhost:6379/11')
    end

    def write(key, object, options = {})
      namespaced = namespaced_key(key, options)

      store.set(namespaced, object)

      if expiration = options[:expires_in]
        store.expire(namespaced, expiration)
      end
    end

    def read(key, options = {})
      namespaced = namespaced_key(key, options)

      store.get(namespaced)
    end

    def fetch(key, options = {})
      value = read(key, options)

      if value.nil? && block_given?
        value = yield
        write(key, value, options)
      end

      value
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
