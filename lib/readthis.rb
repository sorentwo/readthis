require 'readthis/cache'
require 'readthis/serializers'
require 'readthis/version'

module Readthis
  extend self

  def serializers
    @serializers ||= Readthis::Serializers.new
  end
end
