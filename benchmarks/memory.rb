require 'bundler'; Bundler.setup
a = GC.stat(:total_allocated_object)

require 'readthis'
b = GC.stat(:total_allocated_object)

require 'redis-activesupport'
c = GC.stat(:total_allocated_object)

puts "readthis: #{b - a}"
puts "redis-activesupport: #{c - b}"
