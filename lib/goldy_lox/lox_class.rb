# frozen_string_literal: true

module GoldyLox
  class LoxClass
    attr_reader :name

    def initialize(name, methods)
      @name = name
      @methods = methods
    end

    def arity
      find_method("init")&.arity || 0
    end

    def call(interpreter, arguments)
      instance = LoxInstance.new self

      init&.bind(instance)&.call(interpreter, arguments)

      instance
    end

    def find_method(name)
      @methods[name]
    end

    def init
      find_method "init"
    end

    def to_s
      name
    end
  end
end
