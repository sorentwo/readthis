## v0.7.0 2015-08-11

- Changed: Entity initialization uses an options hash rather than keyword
  arguments. This allows flexibility with older Ruby versions (1.9) that aren't
  officially supported.
- Changed: There is no longer a hard dependency on `hiredis`, though it is the
  default. The redis driver can be configured by passing a `driver: :ruby`
  option through to the constructor.

## v0.6.2 2015-04-28

- Fixed: Set expiration during `write_multi`, primarily effecting `fetch_multi`.
  This fixes the real issue underlying the change in `v0.6.1`.

## v0.6.1 2015-04-28

- Changed: Expiration values are always cast to an integer before use in write
  operations. This prevents subtle ActiveSupport bugs where the value would be
  ignored by `setex`.

## v0.6.0 2015-03-09

- Fixed: Safely handle calling `read_multi` without any keys. [Michael Rykov]
- Fixed: Pointed `redis-activesupport` at master. Only effected development and
  testing.
- Added: A `write_multi` method is no available to bulk set keys and values. It
  is used by `fetch_multi` internally to ensure that there are at most two Redis
  calls.

## v0.5.2 2015-01-09

- Fixed: Remove the `pipeline` around `fetch_multi` writing. This will slow down
  `fetch_multi` in cache miss situations for now. It prevents a difficult to
  track down exception in multi-threaded situations.

## v0.5.1 2014-12-30

- Fixed: The `clear` method now accepts an argument for compatibility with other
  caches. The argument is not actually used for anything.
- Changed: The `delete` method will always return a boolean value rather than an
  integer.
- Changed: Avoid multiple instrumentation calls and pool checkouts within
  `fetch_multi` calls.

## v0.5.0 2014-12-12

- Added: All read and write operations are marshalled to and from storage. This
  allows hashes, arrays, etc. to be restored instead of always returning a
  string. Unlike `ActiveSupport::Store::Entity`, no new objects are allocated
  for each entity, reducing GC and improving performance.
- Fixed: Increment/Decrement interface was only accepting two params instead of
  three. Now accepts `amount` as the second parameter.
- Changed: Increment/Decrement no longer use `incby` and `decby`, as they don't
  work with marshalled values. This means they are not entirely atomic, so race
  conditions are possible.

## v0.4.0 2014-12-11

- Added: Force the use of `hiredis` as the adapter. It is dramatically faster,
  but prevents the project from being used in `jruby`. If we get interest from
  some `jruby` projects we can soften the requirement.
- Added: Compression! Adheres to the `ActiveSupport::Store` documentation.
- Fixed: Gracefully handle `nil` passed as `options` to any cache method.

## v0.3.0 2014-12-01

- Added: Use `to_param` for key expansion, only when available. Makes it
  possible to extract a key from any object when ActiveSupport is loaded.
- Added: Expand hashes as cache keys.
- Changed: Use `mget` for `read_multi`, faster and more synchronous than relying on
  `pipelined`.
- Changed: Delimit compound objects with a slash rather than a colon.

## v0.2.0 2014-11-24

- Added: Instrument all caching methods. Will use `ActiveSupport::Notifications`
  if available, otherwise falls back to a polyfill.
- Added: Expand objects with a `cache_key` method and arrays of strings or objects into
  consistent naespaced keys.

## v0.1.0 2014-11-22

- Initial release! Working as a drop in replacement for `redis_store`.
