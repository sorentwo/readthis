# frozen_string_literal: true

module Readthis
  # The `Passthrough` serializer performs no encoding on objects. It should be
  # used when caching simple string objects when the overhead of marshalling or
  # other serialization isn't desired.
  module Passthrough
    # Dump an object to string, without performing any encoding on it.
    #
    # @param [Object] value Any object to be dumped as a string. Frozen strings
    #   will be duplicated.
    #
    # @return [String] The converted object.
    #
    def self.dump(value)
      case value
      when String then value.dup
      else value.to_s
      end
    end

    # Load an object without modifying it at all.
    #
    # @param [String] value The object to return, expected to be a string.
    #
    # @return [String] The original value.
    def self.load(value)
      value
    end
  end
end
