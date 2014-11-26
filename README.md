[![Gem Version](https://badge.fury.io/rb/readthis.svg)](http://badge.fury.io/rb/readthis)
[![Build Status](https://travis-ci.org/sorentwo/readthis.svg?branch=master)](https://travis-ci.org/sorentwo/readthis)

# Readthis

An ActiveSupport::Cache compatible redis based cache focused on speed,
simplicity, and forced pooling.

The only dependencies are `redis` and `connection_pool`.

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
 readthis:read-multi   109.000  i/100ms
  redisas:read-multi    95.000  i/100ms
-------------------------------------------------
 readthis:read-multi      1.112k (± 2.2%) i/s -      5.559k
  redisas:read-multi    978.047  (± 3.9%) i/s -      4.940k

Comparison:
 readthis:read-multi:     1111.7 i/s
  redisas:read-multi:      978.0 i/s - 1.14x slower

Calculating -------------------------------------
readthis:fetch-multi   106.000  i/100ms
 redisas:fetch-multi    84.000  i/100ms
-------------------------------------------------
readthis:fetch-multi      1.077k (± 2.5%) i/s -      5.406k
 redisas:fetch-multi    837.606  (± 4.2%) i/s -      4.200k

Comparison:
readthis:fetch-multi:     1077.2 i/s
 redisas:fetch-multi:      837.6 i/s - 1.29x slower
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'readthis'
```

## Usage

Use it the same way as any other [ActiveSupport::Cache::Store][store]. Readthis
supports all of the standard cache methods except for the following (with
reasons):

* `cleanup` - redis does this with ttl for us already
* `delete_matched` - you really don't want to do perform key matching operations
  in redis. They are linear time and only support basic globbing.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/readthis/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

[store]: http://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html
