require 'readthis/passthrough'

module Readthis
  SerializersFrozenError = Class.new(Exception)
  SerializersLimitError  = Class.new(Exception)

  class Serializers
    BASE_SERIALIZERS = {
      Marshal     => 0x1,
      Passthrough => 0x2,
      JSON        => 0x3
    }.freeze

    SERIALIZER_LIMIT = 7

    attr_reader :serializers

    def initialize
      reset!
    end

    def inverted
      serializers.invert
    end

    def <<(serializer)
      case
      when serializers.frozen?
        raise SerializersFrozenError
      when serializers.length >= SERIALIZER_LIMIT
        raise SerializersLimitError
      else
        @serializers[serializer] = flags.max.succ
      end
    end

    def [](marshal)
      serializers[marshal]
    end

    def freeze!
      serializers.freeze
    end

    def reset!
      @serializers = BASE_SERIALIZERS.dup
    end

    def marshals
      serializers.keys
    end

    def flags
      serializers.values
    end
  end
end
