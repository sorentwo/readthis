module RedisMatchers
  extend RSpec::Matchers::DSL

  matcher :have_ttl do |expected|
    match do |cache|
      cache.pool.with do |client|
        expected.all? do |(key, value)|
          client.ttl(key) == value
        end
      end
    end
  end
end
