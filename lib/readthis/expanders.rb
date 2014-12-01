module Readthis
  module Expanders
    def self.expand(key, namespace = nil)
      expanded = if key.respond_to?(:cache_key)
        key.cache_key
      elsif key.is_a?(Array)
        key.flat_map { |elem| expand(elem) }.join('/')
      else
        key
      end

      namespace ? "#{namespace}/#{expanded}" : expanded
    end
  end
end
