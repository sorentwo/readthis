module Readthis
  module Expanders
    def self.expand_key(key)
      case
      when key.respond_to?(:cache_key)
        key.cache_key
      when key.is_a?(Array)
        key.flat_map { |elem| expand_key(elem) }.join('/')
      when key.is_a?(Hash)
        key.sort_by { |key, _| key.to_s }.map { |key, val| "#{key}=#{val}" }.join('/')
      when key.respond_to?(:to_param)
        key.to_param
      else
        key
      end
    end

    def self.namespace_key(key, namespace)
      expanded = expand_key(key)

      if namespace
        "#{namespace}:#{expanded}"
      else
        expanded
      end
    end
  end
end
