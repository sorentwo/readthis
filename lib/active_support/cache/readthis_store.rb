require 'readthis'

module ActiveSupport
  # Provided for compatibility with ActiveSupport's cache lookup behavior. When
  # the ActiveSupport `cache_store` is set to `:readthis_store` it will resolve
  # to `Readthis::Cache`.
  module Cache
    ReadthisStore ||= Readthis::Cache # rubocop:disable Style/ConstantName
  end
end
