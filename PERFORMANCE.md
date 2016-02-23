Results from the various benchmarks in `./benchmarks`. Hardware doesn't matter
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
 readthis:read-multi   358.000  i/100ms
  redisas:read-multi    94.000  i/100ms
    dalli:read-multi    99.000  i/100ms
-------------------------------------------------
 readthis:read-multi      3.800k (± 2.3%) i/s -     19.332k
  redisas:read-multi    962.199  (± 3.6%) i/s -      4.888k
    dalli:read-multi    995.353  (± 1.1%) i/s -      5.049k

Comparison:
 readthis:read-multi:     3799.8 i/s
    dalli:read-multi:      995.4 i/s - 3.82x slower
  redisas:read-multi:      962.2 i/s - 3.95x slower

Raw Fetch Multi:
Calculating -------------------------------------
readthis:fetch-multi   336.000  i/100ms
 redisas:fetch-multi    86.000  i/100ms
   dalli:fetch-multi   102.000  i/100ms
-------------------------------------------------
readthis:fetch-multi      3.424k (± 2.6%) i/s -     17.136k
 redisas:fetch-multi    874.803  (± 2.7%) i/s -      4.386k
   dalli:fetch-multi      1.028k (± 1.2%) i/s -      5.202k

Comparison:
readthis:fetch-multi:     3424.2 i/s
   dalli:fetch-multi:     1027.7 i/s - 3.33x slower
 redisas:fetch-multi:      874.8 i/s - 3.91x slower

Compressed Writes:
Calculating -------------------------------------
      readthis:write   924.000  i/100ms
         dalli:write   903.000  i/100ms
-------------------------------------------------
      readthis:write     10.105k (± 4.9%) i/s -     50.820k
         dalli:write      9.662k (± 1.6%) i/s -     48.762k

Comparison:
      readthis:write:    10105.3 i/s
         dalli:write:     9662.4 i/s - 1.05x slower

Compressed Read Multi:
Calculating -------------------------------------
 readthis:read_multi   325.000  i/100ms
    dalli:read_multi   100.000  i/100ms
-------------------------------------------------
 readthis:read_multi      3.357k (± 2.3%) i/s -     16.900k
    dalli:read_multi      1.014k (± 3.1%) i/s -      5.100k

Comparison:
 readthis:read_multi:     3356.5 i/s
    dalli:read_multi:     1014.1 i/s - 3.31x slower
```
