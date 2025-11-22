# frozen_string_literal: true

module GoldyLox
  # see https://craftinginterpreters.com/statements-and-state.html#environments
  class Environment
    class UndefinedVariableError < RuntimeError # :nodoc:
      def initialize(message, name)
        super(message)
        @name = name
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

      assert_defined name

      @values[variable_name]
    end

    def put(name, value)
      variable_name = name.lexeme

      assert_defined name

      @values[variable_name] = value
    end

    private

    def assert_defined(name)
      variable_name = name.lexeme

      unless @values.key? variable_name
        raise UndefinedVariableError.new("Undefined variable #{name.lexeme}", name)
      end
    end
  end
end
