# frozen_string_literal: true

module GoldyLox
  # see https://craftinginterpreters.com/statements-and-state.html#environments
  class Environment
    class UndefinedVariableError < RuntimeError # :nodoc:
      def initialize(name)
        @identifier = name
        super("Undefined variable #{name.lexeme}")
      end
    end

    def initialize
      @values = {}
    end

    def define(name, value)
      @values[name] = value
    end

    def get(name)
      variable_name = name.lexeme

      raise UndefinedVariableError.new(name) unless @values.key? variable_name

      @values[variable_name]
    end
  end
end
