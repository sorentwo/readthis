module Readthis
  module Expanders
    def self.expand(key, namespace = nil)
      expanded =
        if key.respond_to?(:cache_key)
          key.cache_key
        elsif key.is_a?(Array)
          key.flat_map { |elem| expand(elem) }.join('/')
        elsif key.is_a?(Hash)
          key.sort_by { |key, _| key.to_s }.map { |key, val| "#{key}=#{val}" }.join('/')
        elsif key.respond_to?(:to_param)
          key.to_param
        else
          key
        end

      namespace ? "#{namespace}:#{expanded}" : expanded
    end
  end
end
