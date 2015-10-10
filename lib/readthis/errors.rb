module Readthis
  ReadthisError = Class.new(StandardError)

  SerializersFrozenError = Class.new(ReadthisError)
  SerializersLimitError  = Class.new(ReadthisError)
  UnknownSerializerError = Class.new(ReadthisError)
end
