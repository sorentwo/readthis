[![Gem Version](https://badge.fury.io/rb/readthis.svg)](http://badge.fury.io/rb/readthis)
[![Build Status](https://travis-ci.org/sorentwo/readthis.svg?branch=master)](https://travis-ci.org/sorentwo/readthis)
[![Code Climate](https://codeclimate.com/github/sorentwo/readthis/badges/gpa.svg)](https://codeclimate.com/github/sorentwo/readthis)
[![Coverage Status](https://coveralls.io/repos/sorentwo/readthis/badge.svg?branch=master&service=github)](https://coveralls.io/github/sorentwo/readthis?branch=master)

# Readthis

Readthis is a drop in replacement for any ActiveSupport compliant cache. It
emphasizes performance and simplicity and takes some cues from Dalli the popular
Memcache client.

For new projects there isn't any reason to stick with Memcached. Redis is as
fast, if not faster in many scenarios, and is far more likely to be used
elsewhere in the stack. See [this blog post][hp-caching] for more details.

[hp-caching]: http://sorentwo.com/2015/07/20/high-performance-caching-with-readthis.html

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

[store]: http://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html

### Instances & Databases

An isolated Redis instance that is only used for caching is ideal. Dedicated
instances have numerous benefits like: more predictable performance, avoiding
expires in favor of LRU, and tuning the persistence mechanism. See [Optimizing
Redis Usage for Caching][optimizing-usage] for more details.

[optimizing-usage]: http://sorentwo.com/2015/07/27/optimizing-redis-usage-for-caching.html

At the very least you'll want to use a specific database for caching. In the
event the database needs to be purged you can do so with a single `clear`
command, rather than finding all keys in a namespace and deleting them.
Appending a number between 0 and 15 will specify the redis database, which
defaults to 0. For example, using database 2:

```bash
REDIS_URL=redis://localhost:6379/2
```

### Expiration

Be sure to use an integer value when setting expiration time. The default
representation of `ActiveSupport::Duration` values won't work when setting
expiration time, which will cause all keys to have `-1` as the TTL. Expiration
values are always cast as an integer on write.

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

### Marshalling

Readthis uses Ruby's `Marshal` module for dumping and loading all values by
default. This isn't always the fastest option, and depending on your use case it
may be desirable to use a faster but less flexible marshaller.

By default Readthis knows about 3 different serializers for marshalling:

* Marshal
* JSON
* Passthrough

If all cached data can safely be represented as a string then use the
pass-through marshaller:

```ruby
Readthis::Cache.new(marshal: Readthis::Passthrough)
```

You can introduce up to four additional marshals by configuring `serializers` on
the Readthis module. For example, if you wanted to use Oj for JSON marshalling,
it is extremely fast, but supports limited types:

```ruby
Readthis.serializers << Oj

# Freeze the serializers to ensure they aren't changed at runtime.
Readthis.serializers.freeze!

Readthis::Cache.new(marshal: Oj)
```

Be aware that the order in which you add serializers matters. Serializers are
sticky and a flag is stored with each cached value. If you subsequently go to
deserialize values and haven't configured the same serializers in the same order
your application will raise errors.

## Differences From ActiveSupport::Cache

Readthis supports all of standard cache methods except for the following:

* `cleanup` - Redis does this with TTL or LRU already.
* `delete_matched` - You really don't want to perform key matching operations in
  Redis. They are linear time and only support basic globbing.

Like other `ActiveSupport::Cache` implementations it is possible to cache `nil`
as a value. However, the fetch methods treat `nil` values as a cache miss and
re-generate/re-cache the value. Caching `nil` isn't recommended.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
