# frozen_string_literal: true

module GoldyLox
  class LoxFunction
    def initialize(declaration, closure, is_initializer)
      @declaration = declaration
      @closure = closure
      @is_initializer = is_initializer
    end

    def arity
      @declaration.parameters.length
    end

    def bind(instance)
      env = Environment.new @closure
      env.define "this", instance

      LoxFunction.new(@declaration, env, @is_initializer)
    end

    def call(interpreter, arguments)
      env = Environment.new @closure
      @declaration.parameters.each_with_index do |parameter, i|
        env.define parameter.lexeme, arguments[i]
      end

      interpreter.execute_block @declaration.body, env

      return @closure.get_at(0, "this") if @is_initializer

      nil
    rescue Interpreter::Return => e
      return @closure.get_at(0, "this") if @is_initializer

      e.value
    end
  end

  class NativeFunction
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
