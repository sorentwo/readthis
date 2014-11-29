[![Gem Version](https://badge.fury.io/rb/readthis.svg)](http://badge.fury.io/rb/readthis)
[![Build Status](https://travis-ci.org/sorentwo/readthis.svg?branch=master)](https://travis-ci.org/sorentwo/readthis)

# Readthis

Readthis is a drop in replacement for any ActiveSupport compliant cache, but
emphasizes performance and simplicity. It takes some cues from Dalli (connection
pooling), the popular Memcache client. Below are some performance comparisons
against the only other notable redis cache implementation, `redis-activesupport`,
which has been abandoned and doesn't actually comply to Rails 4.2 cache store
behavior for `fetch_multi`.

## Footprint & Performance

Footprint compared to `redis-activesupport`:

```
# Total allocated objects after require
readthis: 19,964
redis-activesupport: 78,630
```

Performance compared to `redis-activesupport` for \*multi operations:

```
Calculating -------------------------------------
 readthis:read-multi   117.000  i/100ms
  redisas:read-multi    98.000  i/100ms
-------------------------------------------------
 readthis:read-multi      1.241k (± 3.5%) i/s -      6.201k
  redisas:read-multi    958.080  (± 4.7%) i/s -      4.802k

Comparison:
 readthis:read-multi:     1241.3 i/s
  redisas:read-multi:      958.1 i/s - 1.30x slower

Calculating -------------------------------------
readthis:fetch-multi   114.000  i/100ms
 redisas:fetch-multi    84.000  i/100ms
-------------------------------------------------
readthis:fetch-multi      1.192k (± 4.1%) i/s -      6.042k
 redisas:fetch-multi    844.769  (± 3.4%) i/s -      4.284k

Comparison:
readthis:fetch-multi:     1192.1 i/s
 redisas:fetch-multi:      844.8 i/s - 1.41x slower
```

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

```
REDIS_URL=redis://localhost:6379/2
```

## Differences

Readthis supports all of standard cache methods except for the following:

* `cleanup` - redis does this with ttl for us already
* `delete_matched` - you really don't want to perform key matching operations
  in redis. They are linear time and only support basic globbing.

[store]: http://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html
