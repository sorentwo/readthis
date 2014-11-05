# silence
# mute
# fetch
# read_multi
# fetch_multi
#
# delete_matched
# increment
# decrement
# cleanup
# clear
#
# read_entry
# write_entry
# delete_entry
#
# exist?
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

    private

    def namespaced_key(key, options)
      namespace = options[:namespace]

      [namespace, key].join(':')
    end
  end
end
