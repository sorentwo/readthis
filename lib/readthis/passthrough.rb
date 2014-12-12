module Readthis
  module Passthrough
    def self.dump(value)
      value
    end

    def self.load(value)
      value
    end
  end
end
