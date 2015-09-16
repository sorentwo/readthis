require 'readthis/cache'
require 'readthis/version'
require 'readthis/serializers'

module Readthis
  extend self

  def serializers
    @serializers ||= Readthis::Serializers.new
  end
end
