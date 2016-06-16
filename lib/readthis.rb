require 'readthis/cache'
require 'readthis/errors'
require 'readthis/serializers'
require 'readthis/version'

module Readthis
  # The current, global, instance of serializers that is used by all cache
  # instances.
  #
  # @return [Readthis::Serializers] An cached Serializers instance
  #
  # @see readthis/serializers
  #
  def serializers
    @serializers ||= Readthis::Serializers.new
  end

  # Indicates whether connection error tolerance is enabled. With tolerance
  # enabled every operation will return a `nil` value.
  #
  # @return [Boolean] True for enabled, false for disabled
  #
  def fault_tolerant?
    @fault_tolerant
  end

  # Toggle fault tolerance for connection errors.
  #
  # @param [Boolean] value The new value for fault tolerance
  #
  def fault_tolerant=(value)
    @fault_tolerant = value
  end

  # @private
  def reset!
    @fault_tolerant = nil
    @serializers = nil
  end

  module_function :serializers, :fault_tolerant?, :fault_tolerant=, :reset!
end
