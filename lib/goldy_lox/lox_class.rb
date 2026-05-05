# frozen_string_literal: true

module GoldyLox
  class LoxClass
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def to_s
      name
    end
  end
end
