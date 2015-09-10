require 'benchmark/ips'

def compose_a(marshal, compress)
  prefix = ''
  prefix << 'R|'.freeze
  prefix << marshal.name.ljust(24)
  prefix << (compress ? '1'.freeze : '0'.freeze)
  prefix << 1
  prefix << '|R'.freeze
end

def compose_b(marshal, compress)
  "R|#{marshal.name.ljust(24)}#{compress ? '1'.freeze : '0'.freeze}1|R"
end

def compose_c(marshal, compress)
  name = marshal.name.ljust(24)
  comp = compress ? '1'.freeze : '0'.freeze

  "R|#{name}#{comp}1|R"
end

SERIALIZER_FLAG = { Marshal => 0x1 }.freeze
COMPRESSED_FLAG = 0x8

# | 0000 | 0 | 000 |
# four unused bits, # 1 compression bit, 3 bits for serializer, allow up to 8
# different marshalers
def compose_d(marshal, compress)
  flags  = SERIALIZER_FLAG[marshal]
  flags |= COMPRESSED_FLAG if compress

  [flags].pack('C')
end

Benchmark.ips do |x|
  x.report('a') { compose_a(Marshal, true) }
  x.report('b') { compose_b(Marshal, true) }
  x.report('c') { compose_c(Marshal, true) }
  x.report('d') { compose_d(Marshal, true) }

  x.compare!
end
