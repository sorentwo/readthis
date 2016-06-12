local expire = ARGV[1]

for index = 1, #KEYS do
  redis.call('EXPIRE', KEYS[index], expire)
end

return true
