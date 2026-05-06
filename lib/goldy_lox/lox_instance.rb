# frozen_string_literal: true

module GoldyLox
  class LoxInstance
    def initialize(klass)
      @klass = klass
    end

    def to_s
      "#{@klass} instance"
    end
  end
end
