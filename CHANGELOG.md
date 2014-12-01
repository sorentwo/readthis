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
