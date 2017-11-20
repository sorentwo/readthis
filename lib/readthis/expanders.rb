module Readthis
  module Expanders
    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
    def self.expand_key(key)
      case
      when key.is_a?(String)
        key.frozen? ? key.dup : key
      when key.is_a?(Array)
        key.flat_map { |elem| expand_key(elem) }.join('/')
      when key.is_a?(Hash)
        key
          .sort_by { |hkey, _| hkey.to_s }
          .map { |hkey, val| "#{hkey}=#{val}" }
          .join('/')
      when key.respond_to?(:cache_key)
        key.cache_key
      when key.respond_to?(:to_param)
        key.to_param
      else
        key.to_s
      end
    end

    def self.namespace_key(key, namespace)
      expanded = expand_key(key)

      if namespace
        "#{namespace}:#{expanded}"
      else
        expanded
      end.force_encoding(Encoding::BINARY)
    end
  end
end
