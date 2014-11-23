# Readthis

An ActiveSupport::Cache compatible redis based cache focused on speed,
simplicity, and forced pooling.

The only dependencies are `redis` and `connection_pool`.

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
