require 'benchmark/ips'

def parse_a(string)
  marshal  = string[2, 12].strip
  compress = string[15] == '1'.freeze

  [marshal, compress, string[18..-1]]
end

def parse_b(marked)
  prefix = marked[0, 32].scrub('*'.freeze)[/R\|(.*)\|R/, 1]
  offset = prefix.size + 4

  marshal, c_name, _ = prefix.split('|'.freeze)

  compress = c_name == 'true'.freeze

  [marshal, compress, marked[offset..-1]]
end

STR = 'R|marshal      0|Rafdlkadfjadfj asdlkfjasdlfkj asdlfkjdasflkjadsflkjadslkjfadslkjfasdlkjfadlskjf laksdjflkajsdflkjadsflkadjsfladskjf laksjflakdjfalsdkjfadlskjf laksdjflkajdsflk j'

Benchmark.ips do |x|
  x.report('a') { parse_a(STR) }
  x.report('b') { parse_b(STR) }

  x.compare!
end
