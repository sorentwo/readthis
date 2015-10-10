## Unreleased

- Changed: All errors now extend from a base `ReadthisError`.

## v1.0.0 2015-10-05

- Changed: Remove internal `Notifications` module as part of instrumentation
  cleanup.

## v1.0.0-rc.1 2015-09-27

- Fixed: Custom serializers would be encoded correcty, but would be ignored when
  the value was read back out, leaving the encoding flags prefixed to the value.
- Changed: There are no longer direct accessors for `namespace` and
  `expires_in`. Instead, the exposed `options` hash is used as the fallback for
  all operations. For `ActiveSupport` compliance options must be exposed, so this
  prevents configuration drift after initialization. [readthis#21][issue-21]
- Added: More helpful errors are raised when attempting to use a serializer that
  hasn't been configured. [readthis#22][issue-22].

[issue-21]: https://github.com/sorentwo/readthis/issues/21
[issue-22]: https://github.com/sorentwo/readthis/issues/22

## v1.0.0-beta 2015-09-18

- Breaking: This change is necessary for the consistency and portability of
  values going forward. All entities are now written with a set of option flags
  as the initial byte. This flag is later used to determine whether the entity
  was compressed and what was used to marshal it. There are a number of
  advantages to this approach, consistency and reliability being the most
  important. See [readthis#17][pull-17] for additional background.
- Added: Per-entity options can be passed through to any cache method that
  writes a value (`write`, `fetch`, etc). For example, this allows certain
  entities to be cached as JSON while all other entities are cached using
  Marshal. Thanks to @fabn.
- Fixed: A hash containing the cache key is passed as the payload for
  `ActiveSupport::Notifications` instrumentation, rather than the key directly.
  This moves the implementation in-line with the tests for the code, and
  prevents errors from being masked when an error occurs inside an instrumented
  block. [readthis#20][pull-20]. Discovered by @banister and fixed by @workmad3.

[pull-17]: https://github.com/sorentwo/readthis/pull/17
[pull-20]: https://github.com/sorentwo/readthis/pull/20

## v0.8.1 2015-09-04

- Changed: `Readthis::Cache` now has an accessor for the options that were
  passed during initialization. This is primarily to support the session store
  middleware provided by `ActionDispatch`. See [readthis#16][issue-16].
- Fixed: Caching `nil` values is now possible. Previously the value would be
  converted into a blank string, causing a Marshal error when loading the data.
  There is still some non-standard handling of `nil` within `fetch` or
  `fetch_multi`, where a cached `nil` value will always result in a cache miss.
  See [readthis#15][issue-15].
- Fixed: Entity compression was broken, it wouldn't unload data when the
  compressed size was below the compression limit. Data is now decompressed
  when it can the value looks to be compressed, falling back to the initial
  value when decompression fails. See [readthis#13][issue-13] for details.

[issue-13]: https://github.com/sorentwo/readthis/issues/13
[issue-15]: https://github.com/sorentwo/readthis/issues/15
[issue-16]: https://github.com/sorentwo/readthis/issues/16

## v0.8.0 2015-08-26

- Breaking: The initializer now takes a single options argument instead of a
  `url` and `options` separately. This allows the underlying redis client to
  accept any options, rather than just the driver. For example, it's now
  possible to use Readthis with sentinel directly through the configuration.
- Changed: The `hiredis` driver is *no longer the default*. In order to use the
  vastly faster `hiredis` driver you need to pass it in during construction.
  See [readthis#9][issue-9] for more discussion.

[issue-9]: https://github.com/sorentwo/readthis/issues/9

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
