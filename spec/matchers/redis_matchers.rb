module RedisMatchers
  extend RSpec::Matchers::DSL

  matcher :have_ttl do |expected|
    match do |cache|
      cache.pool.with do |client|
        expected.each do |key, value|
          client.ttl(key) == value
        end
      end
    end
  end
end
