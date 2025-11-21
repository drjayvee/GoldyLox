# frozen_string_literal: true

module GoldyLox
  # see https://craftinginterpreters.com/statements-and-state.html#environments
  class Environment
    class UndefinedVariableError < RuntimeError # :nodoc:
      def initialize(identifier)
        @identifier = identifier
        super("Undefined variable #{identifier.lexeme}")
      end
    end

    def initialize
      @values = {}
    end

    def define(name, value)
      @values[name] = value
    end

    def get(identifier)
      variable_name = identifier.lexeme

      raise UndefinedVariableError, identifier unless @values.key? variable_name

      @values[variable_name]
    end
  end
end
