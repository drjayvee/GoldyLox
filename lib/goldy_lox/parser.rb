# frozen_string_literal: true

require_relative "parser/parse_error"
require_relative "parser/grammar"
require_relative "parser/token_utilities"

module GoldyLox
  class Parser # :nodoc:
    attr_reader :errors

    def initialize(tokens)
      @tokens = tokens
      @current = 0
    end

    def parse
      statements = []
      statements << declaration until end? || match?(:eof)

      statements
    end

    private

    include TokenUtilities
    include Grammar

    def error(token, message)
      raise ParseError.new(message, token)
    end

    def synchronize
      advance

      until end?
        return if previous.type == :semicolon

        case peek.type
        when :class, :fun, :var, :for, :if, :while, :print, :return
          return
        else
          advance
        end
      end
    end
  end
end
