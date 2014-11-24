module Readthis
  module Notifications
    def self.instrument(name, payload)
      yield(payload)
    end
  end
end
