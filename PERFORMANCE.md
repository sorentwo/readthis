Results from the various benchmarks in `./bencharks`. Hardware doesnt't matter
much, as we're simply looking for a comparison against other libraries and prior
verions.

## Footprint

Footprint compared to `redis-activesupport`:

```
# Total allocated objects after require
readthis: 20602
redis-activesupport: 78630
```

## Performance

Performance compared to `dalli` and `redis-activesupport`:

```
Raw Read Multi:
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

Raw Fetch Multi:
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

Compressed Writes:
Calculating -------------------------------------
      readthis:write     1.003k i/100ms
         dalli:write   913.000  i/100ms
-------------------------------------------------
      readthis:write     11.095k (± 5.7%) i/s -     56.168k
         dalli:write      9.829k (± 1.8%) i/s -     49.302k

Comparison:
      readthis:write:    11095.5 i/s
         dalli:write:     9828.8 i/s - 1.13x slower

Compressed Read Multi:
Calculating -------------------------------------
 readthis:read_multi   446.000  i/100ms
    dalli:read_multi    97.000  i/100ms
-------------------------------------------------
 readthis:read_multi      4.728k (± 4.6%) i/s -     23.638k
    dalli:read_multi    985.986  (± 3.9%) i/s -      4.947k

Comparison:
 readthis:read_multi:     4728.3 i/s
    dalli:read_multi:      986.0 i/s - 4.80x slower
```
