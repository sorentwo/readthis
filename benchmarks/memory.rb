require 'bundler'; Bundler.setup
a = GC.stat(:total_allocated_objects)

require 'readthis'
b = GC.stat(:total_allocated_objects)

require 'redis-activesupport'
c = GC.stat(:total_allocated_objects)

puts "readthis: #{b - a}"
puts "redis-activesupport: #{c - b}"
