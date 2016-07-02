# frozen_string_literal: true

module Readthis
  module Passthrough
    def self.dump(value)
      value.dup
    end

    def self.load(value)
      value
    end
  end
end
