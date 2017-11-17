# frozen_string_literal: true

module Readthis
  module Passthrough
    def self.dump(value)
      case value
      when String then value.dup
      else value.to_s
      end
    end

    def self.load(value)
      value
    end
  end
end
