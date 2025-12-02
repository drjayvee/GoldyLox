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

    def initialize(enclosing = nil)
      @enclosing = enclosing
      @values = {}
    end

    def define(name, value)
      @values[name] = value
    end

    def get(name)
      variable_name = name.lexeme

      return @values[variable_name] if @values.key?(variable_name)

      return @enclosing.get(name) unless @enclosing.nil?

      raise UndefinedVariableError.new("Undefined variable #{variable_name}", name)
    end

    def assign(name, value)
      variable_name = name.lexeme

      if @values.key?(variable_name)
        @values[variable_name] = value
        return
      end

      unless @enclosing.nil?
        @enclosing.assign name, value
        return
      end

      raise UndefinedVariableError.new("Undefined variable #{variable_name}", name)
    end
  end
end
