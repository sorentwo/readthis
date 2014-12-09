[![Gem Version](https://badge.fury.io/rb/readthis.svg)](http://badge.fury.io/rb/readthis)
[![Build Status](https://travis-ci.org/sorentwo/readthis.svg?branch=master)](https://travis-ci.org/sorentwo/readthis)
[![Code Climate](https://codeclimate.com/github/sorentwo/readthis/badges/gpa.svg)](https://codeclimate.com/github/sorentwo/readthis)

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
readthis: 20602
redis-activesupport: 78630
```

Performance compared to `dalli` and `redis-activesupport` for \*multi
operations:

```
Calculating -------------------------------------
 readthis:read-multi   500.000  i/100ms
  redisas:read-multi    95.000  i/100ms
    dalli:read-multi    97.000  i/100ms
-------------------------------------------------
 readthis:read-multi      5.286k (± 2.7%) i/s -     26.500k
  redisas:read-multi    959.405  (± 4.2%) i/s -      4.845k
    dalli:read-multi    978.803  (± 2.1%) i/s -      4.947k

Comparison:
 readthis:read-multi:     5286.0 i/s
    dalli:read-multi:      978.8 i/s - 5.40x slower
  redisas:read-multi:      959.4 i/s - 5.51x slower

Calculating -------------------------------------
readthis:fetch-multi   448.000  i/100ms
 redisas:fetch-multi    84.000  i/100ms
   dalli:fetch-multi    99.000  i/100ms
-------------------------------------------------
readthis:fetch-multi      4.682k (± 2.4%) i/s -     23.744k
 redisas:fetch-multi    848.101  (± 3.2%) i/s -      4.284k
   dalli:fetch-multi      1.006k (± 2.4%) i/s -      5.049k

Comparison:
readthis:fetch-multi:     4682.4 i/s
   dalli:fetch-multi:     1005.6 i/s - 4.66x slower
 redisas:fetch-multi:      848.1 i/s - 5.52x slower
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
