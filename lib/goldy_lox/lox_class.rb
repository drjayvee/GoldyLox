# frozen_string_literal: true

module GoldyLox
  class LoxClass
    attr_reader :name

    def initialize(name, methods)
      @name = name
      @methods = methods
    end

    def arity
      0
    end

    def call(_interpreter, _arguments)
      LoxInstance.new self
    end

    def find_method(name)
      @methods[name]
    end

    def to_s
      name
    end
  end
end
