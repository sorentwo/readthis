[![Gem Version](https://badge.fury.io/rb/readthis.svg)](http://badge.fury.io/rb/readthis)
[![Build Status](https://travis-ci.org/sorentwo/readthis.svg?branch=master)](https://travis-ci.org/sorentwo/readthis)
[![Code Climate](https://codeclimate.com/github/sorentwo/readthis/badges/gpa.svg)](https://codeclimate.com/github/sorentwo/readthis)
[![Coverage Status](https://coveralls.io/repos/sorentwo/readthis/badge.svg?branch=master&service=github)](https://coveralls.io/github/sorentwo/readthis?branch=master)
[![Inline Docs](http://inch-ci.org/github/sorentwo/readthis.svg?branch=master)](http://inch-ci.org/github/sorentwo/readthis)

# Readthis

Readthis is a Redis backed cache client for Ruby. It is a drop in replacement
for any `ActiveSupport` compliant cache and can also be used for [session
storage](#session-storage). Above all Readthis emphasizes performance,
simplicity, and explicitness.

For new projects there isn't any reason to stick with Memcached. Redis is as
fast, if not faster in many scenarios, and is far more likely to be used
elsewhere in the stack. See [this blog post][hp-caching] for more details.

[hp-caching]: http://sorentwo.com/2015/07/20/high-performance-caching-with-readthis.html

## Rails 5.2+

Rails 5.2 and beyond has a [Redis Cache][rc] built in. The built in Redis cache
supports many of the same features as Readthis, as well as multi-tier caches and
newer additions like cache key recycling.

_Readthis is maintained for versions of Rails prior to 5.2 and new features will
not be supported. If you are using Rails 5.2+ you should migrate to the built in
Redis cache._

[rc]: https://api.rubyonrails.org/classes/ActiveSupport/Cache/RedisCacheStore.html

## Footprint & Performance

See [Performance](PERFORMANCE.md)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'readthis'
gem 'hiredis' # Highly recommended
```

## Usage

Use it the same way as any other [ActiveSupport::Cache::Store][store]. Within a
Rails environment config:

```ruby
config.cache_store = :readthis_store, {
  expires_in: 2.weeks.to_i,
  namespace: 'cache',
  redis: { url: ENV.fetch('REDIS_URL'), driver: :hiredis }
}
```

Otherwise you can use it anywhere, without any reliance on `ActiveSupport`:

```ruby
require 'readthis'

cache = Readthis::Cache.new(
  expires_in: 2.weeks.to_i,
  redis: { url: ENV.fetch('REDIS_URL') }
)
```

You can also specify `host`, `port`, `db` or any other valid Redis options. For
more details about connection options see in [redis gem documentation][redisrb]

[store]: http://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html
[redisrb]: https://github.com/redis/redis-rb#getting-started

### Instances & Databases

An isolated Redis instance that is only used for caching is ideal. Dedicated
instances have numerous benefits like: more predictable performance, avoiding
expires in favor of LRU, and tuning the persistence mechanism. See [Optimizing
Redis Usage for Caching][optimizing-usage] for more details.

At the very least, you'll want to use a specific database for caching. In the
event the database needs to be purged you can do so with a single `clear`
command, rather than finding all keys in a namespace and deleting them.
Appending a number between 0 and 15 will specify the redis database, which
defaults to `0`. For example, using database `2`:

```bash
REDIS_URL=redis://localhost:6379/2
```

[optimizing-usage]: http://sorentwo.com/2015/07/27/optimizing-redis-usage-for-caching.html

### Expiration

Be sure to use an integer value when setting expiration time. The default
representation of `ActiveSupport::Duration` values won't work when setting
expiration time, which will cause all keys to have `-1` as the TTL. Expiration
values are always cast as an integer on write. For example:

```ruby
Readthis::Cache.new(expires_in: 1.week) # don't do this
Readthis::Cache.new(expires_in: 1.week.to_i) # do this
```

By using the `refresh` option the TTL for keys can be refreshed automatically
every time the key is read. This is helpful for ensuring commonly hit keys are
kept cached, effectively making the cache a hybrid LRU.

```ruby
Readthis::Cache.new(refresh: true)
```

Be aware that `refresh` adds a slight overhead to all read operations, as they
are now all write operations as well.

### Compression

Compression can be enabled for all actions by passing the `compress` flag. By
default all values greater than 1024k will be compressed automatically. If there
is any content has not been stored with compression, or perhaps was compressed
but is beneath the compression threshold, it will be passed through as is. This
means it is safe to enable or change compression with an existing cache. There
will be a decoding performance penalty in this case, but it should be minor.

```ruby
config.cache_store = :readthis_store, {
  compress: true,
  compression_threshold: 2.kilobytes
}
```

### Serializing

Readthis uses Ruby's `Marshal` module for serializing all values by default.
This isn't always the fastest option, and depending on your use case it may be
desirable to use a faster but less flexible serializer.

By default Readthis knows about 3 different serializers:

* Marshal
* JSON
* Passthrough

If all cached data can safely be represented as a string then use the
pass-through serializer:

```ruby
Readthis::Cache.new(marshal: Readthis::Passthrough)
```

You can introduce up to four additional serializers by configuring `serializers`
on the Readthis module. For example, if you wanted to use the extremely fast Oj
library for JSON serialization:

```ruby
Readthis.serializers << Oj

# Freeze the serializers to ensure they aren't changed at runtime.
Readthis.serializers.freeze!

Readthis::Cache.new(marshal: Oj)
```

Be aware that the *order in which you add serializers matters*. Serializers are
sticky and a flag is stored with each cached value. If you subsequently go to
deserialize values and haven't configured the same serializers in the same order
your application will raise errors.

## Fault Tolerance

In some situations it is desirable to keep serving requests from disk or the
database if Redis crashes. This can be achieved with connection fault tolerance
by enabling it at the top level:

```ruby
Readthis.fault_tolerant = true
```

The default value is `false`, because while it may work for `fetch` operations,
it isn't compatible with other state-based commands like `increment`.

## Running Arbitrary Redis Commands

Readthis provides access to the underlying Redis connection pool, allowing you
to run arbitrary commands directly through the cache instance. For example, if
you wanted to expire a key manually using an instance of `Rails.cache`:

```ruby
Rails.cache.pool.with { |client| client.expire('foo-key', 60) }
```

## Differences From ActiveSupport::Cache

Readthis supports all of standard cache methods except for the following:

* `cleanup` - Redis does this with TTL or LRU already.
* `mute` and `silence!` - You must subscribe to the events `/cache*.active_support/`
  with `ActiveSupport::Notifications` to [log cache calls manually][notifications].

[notifications]: https://github.com/sorentwo/readthis/issues/22#issuecomment-142595938

Like other `ActiveSupport::Cache` implementations it is possible to cache `nil`
as a value. However, the fetch methods treat `nil` values as a cache miss and
re-generate/re-cache the value. Caching `nil` isn't recommended.

## Session Storage

By using [ActionDispatch::Session::CacheStore][cache-store] it's possible to
reuse `:readthis_store` or specify a new Readthis cache store for storing
sessions.

```ruby
Rails.application.config.session_store :cache_store
```

To specify a separate Readthis instance you can use the `:cache` option:

```ruby
Rails.application.config.session_store :cache_store,
  cache: Readthis::Cache.new,
  expire_after: 2.weeks.to_i
```

[cache-store]: http://api.rubyonrails.org/classes/ActionDispatch/Session/CacheStore.html

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
