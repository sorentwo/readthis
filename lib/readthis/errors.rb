module Readthis
  # This is the base error that all other specific errors inherit from,
  # making it possible to rescue the `ReadthisError` superclass.
  #
  # This isn't raised by itself.
  ReadthisError = Class.new(StandardError)

  # Raised when attempting to modify the serializers after they have been
  # frozen.
  SerializersFrozenError = Class.new(ReadthisError)

  # Raised when attempting to add a new serializer after the limit of 7 is
  # reached.
  SerializersLimitError  = Class.new(ReadthisError)

  # Raised when an unknown script is called.
  UnknownCommandError = Class.new(ReadthisError)

  # Raised when a serializer was specified, but hasn't been configured for
  # usage.
  UnknownSerializerError = Class.new(ReadthisError)
end
