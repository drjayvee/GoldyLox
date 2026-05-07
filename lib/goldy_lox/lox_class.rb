# frozen_string_literal: true

module GoldyLox
  class LoxClass
    attr_reader :name

    def initialize(name, super_class, methods)
      @name = name
      @super_class = super_class
      @methods = methods
    end

    def arity
      initializer&.arity || 0
    end

    def call(interpreter, arguments)
      instance = LoxInstance.new self

      initializer&.bind(instance)&.call(interpreter, arguments)

      instance
    end

    def find_method(name)
      @methods[name]
    end

    def initializer = find_method "init"

    def to_s
      name
    end
  end
end
