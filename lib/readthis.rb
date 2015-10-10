require 'readthis/cache'
require 'readthis/errors'
require 'readthis/serializers'
require 'readthis/version'

module Readthis
  extend self

  def serializers
    @serializers ||= Readthis::Serializers.new
  end
end
