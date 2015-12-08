require 'readthis/cache'
require 'readthis/errors'
require 'readthis/serializers'
require 'readthis/version'

module Readthis
  extend self

  # The current, global, instance of serializers that is used by all cache
  # instances.
  #
  # @returns [Readthis::Serializers] An cached Serializers instance
  #
  # @see readthis/serializers
  #
  def serializers
    @serializers ||= Readthis::Serializers.new
  end

  def fault_tolerant?
    true
  end
end
