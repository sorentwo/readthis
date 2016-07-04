require 'json'
require 'readthis/errors'
require 'readthis/passthrough'

module Readthis
  class Serializers
    # Defines the default set of three serializers: Marshal, Passthrough, and
    # JSON. With a hard limit of 7 that leaves 4 additional slots.
    BASE_SERIALIZERS = {
      Marshal     => 0x1,
      Passthrough => 0x2,
      JSON        => 0x3
    }.freeze

    # The hard serializer limit, based on the number of possible values within
    # a single 3bit integer.
    SERIALIZER_LIMIT = 7

    attr_reader :serializers, :inverted

    # Creates a new Readthis::Serializers entity. No configuration is expected
    # during initialization.
    #
    def initialize
      reset!
    end

    # Append a new serializer. Up to 7 total serializers may be configured for
    # any single application be configured for any single application. This
    # limit is based on the number of bytes available in the option flag.
    #
    # @param [Module] serializer Any object that responds to `dump` and `load`
    # @return [self] Returns itself for possible chaining
    #
    # @example
    #
    #     serializers = Readthis::Serializers.new
    #     serializers << Oj
    #
    def <<(serializer)
      case
      when serializers.frozen?
        raise SerializersFrozenError
      when serializers.length >= SERIALIZER_LIMIT
        raise SerializersLimitError
      else
        @serializers[serializer] = flags.max.succ
        @inverted = @serializers.invert
      end

      self
    end

    # Freeze the serializers hash, preventing modification.
    #
    def freeze!
      serializers.freeze
    end

    # Reset the instance back to the default state. Useful for cleanup during
    # testing.
    #
    def reset!
      @serializers = BASE_SERIALIZERS.dup
      @inverted = @serializers.invert
    end

    # Find a flag for a serializer object.
    #
    # @param [Object] serializer Look up a flag by object
    # @return [Number] Corresponding flag for the serializer object
    # @raise [UnknownSerializerError] Indicates that a serializer was
    #   specified, but hasn't been configured for usage.
    #
    # @example
    #
    #   serializers.assoc(JSON) #=> 1
    #
    def assoc(serializer)
      flag = serializers[serializer]

      unless flag
        raise UnknownSerializerError, "'#{serializer}' hasn't been configured"
      end

      flag
    end

    # Find a serializer object by flag value.
    #
    # @param [Number] flag Integer to look up the serializer object by
    # @return [Module] The serializer object
    #
    # @example
    #
    #   serializers.rassoc(1) #=> Marshal
    #
    def rassoc(flag)
      inverted[flag & SERIALIZER_LIMIT]
    end

    # @private
    def marshals
      serializers.keys
    end

    # @private
    def flags
      serializers.values
    end
  end
end
