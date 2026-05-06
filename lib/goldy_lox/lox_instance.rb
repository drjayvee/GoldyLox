# frozen_string_literal: true

module GoldyLox
  class LoxInstance
    def initialize(klass)
      @klass = klass
      @fields = {}
    end

    def get(name)
      property = name.lexeme

      if (method = @klass.find_method(property))
        return method.bind self
      end

      raise "Invalid property '#{property}' for get" unless @fields.key? property

      @fields[property]
    end

    def set(name, value)
      @fields[name.lexeme] = value
    end

    def to_s
      "#{@klass} instance"
    end
  end
end
