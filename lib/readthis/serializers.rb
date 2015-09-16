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

    attr_reader :serializers, :inverted

    def initialize
      reset!
    end

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
    end

    def assoc(marshal)
      serializers[marshal]
    end

    def rassoc(flag)
      inverted[flag]
    end

    def freeze!
      serializers.freeze
    end

    def reset!
      @serializers = BASE_SERIALIZERS.dup
      @inverted = @serializers.invert
    end

    def marshals
      serializers.keys
    end

    def flags
      serializers.values
    end
  end
end
