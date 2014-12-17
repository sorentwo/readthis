[![Gem Version](https://badge.fury.io/rb/readthis.svg)](http://badge.fury.io/rb/readthis)
[![Build Status](https://travis-ci.org/sorentwo/readthis.svg?branch=master)](https://travis-ci.org/sorentwo/readthis)
[![Code Climate](https://codeclimate.com/github/sorentwo/readthis/badges/gpa.svg)](https://codeclimate.com/github/sorentwo/readthis)
[![Coverage Status](https://img.shields.io/coveralls/sorentwo/readthis.svg)](https://coveralls.io/r/sorentwo/readthis?branch=master)

# Readthis

Readthis is a drop in replacement for any ActiveSupport compliant cache, but
emphasizes performance and simplicity. It takes some cues from Dalli (connection
pooling), the popular Memcache client.

For any new projects there isn't any reason to stick with Memcached. Redis is
as fast, if not faster in many scenarios, and is far more likely to be used
elsewhere in the stack. See [this Stack Overflow post][stackoverflow] for more
details.

[stackoverflow]: http://stackoverflow.com/questions/10558465/memcache-vs-redis

## Footprint & Performance

See [Performance](PERFORMANCE.md)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'readthis'
```

## Usage

Use it the same way as any other [ActiveSupport::Cache::Store][store]. Within a
rails environment config:

```ruby
config.cache_store = :readthis_store, ENV.fetch('REDIS_URL'), {
  expires_in: 2.weeks,
  namespace: 'cache'
}
```

Otherwise you can use it anywhere, without any reliance on ActiveSupport:

```ruby
require 'readthis'

cache = Readthis::Cache.new(ENV.fetch('REDIS_URL'), expires_in: 2.weeks)
```

You'll want to use a specific database for caching, just in case you need to
clear the cache entirely. Appending a number between 0 and 15 will specify the
redis database, which defaults to 0. For example, using database 2:

```bash
REDIS_URL=redis://localhost:6379/2
```

[store]: http://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html

### Compression

Compression can be enabled for all actions by passing the `compress` flag. By
default all values greater than 1024k will be compressed automatically. If there
is any content has not been stored with compression, or perhaps was compressed
but is beneath the compression threshold, it will be passed through as is. This
means it is safe to enable or change compression with an existing cache. There
will be a decoding performance penalty in this case, but it should be minor.

```ruby
config.cache_store = :readthis_store, ENV.fetch('REDIS_URL'), {
  compress: true,
  compression_threshold: 2.kilobytes
}
```

### Marshalling

Readthis uses Ruby's `Marshal` module for dumping and loading all values by
default. This isn't always the fastest option, depending on your use case it may
be desirable to use a faster but more flexible marshaller.

Use Oj for JSON marshalling, extremely fast, limited types:

```ruby
Readthis::Cache.new(marshal: Oj)
```

If you don't mind everything being a string then use the Passthrough marshal:

```ruby
Readthis::Cache.new(marshal: Readthis::Passthrough)
```

## Differences

Readthis supports all of standard cache methods except for the following:

* `cleanup` - redis does this with ttl for us already
* `delete_matched` - you really don't want to perform key matching operations
  in redis. They are linear time and only support basic globbing.
