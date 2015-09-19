require 'readthis'

module ActiveSupport
  module Cache
    ReadthisStore ||= Readthis::Cache # rubocop:disable Style/ConstantName
  end
end
