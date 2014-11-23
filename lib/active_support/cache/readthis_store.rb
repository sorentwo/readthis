require 'readthis'

module ActiveSupport
  module Cache
    ReadthisStore ||= Readthis::Cache
  end
end
