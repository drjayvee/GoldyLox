# frozen_string_literal: true

module GoldyLox
  class LoxFunction # :nodoc:
    def initialize(declaration, closure)
      @declaration = declaration
      @closure = closure
    end

    def arity
      @declaration.parameters.length
    end

    def call(interpreter, arguments)
      env = Environment.new @closure
      @declaration.parameters.each_with_index do |parameter, i|
        env.define parameter.lexeme, arguments[i]
      end

      interpreter.execute_block @declaration.body, env
    end
  end

  class NativeFunction # :nodoc:
    attr_reader :arity

    def initialize(arity, &block)
      @arity = arity
      @block = block
    end

    def call(_, arguments)
      @block.call(arguments)
    end
  end
end
