# frozen_string_literal: true

module GoldyLox
  # Token
  # see https://craftinginterpreters.com/scanning.html#lexemes-and-tokens
  class Token
    TYPES = %i[
      left_paren right_paren left_brace right_brace
      comma dot minus plus semicolon slash star

      bang bang_equal equal bang_equal
      greater greater_equal less less_equal

      identifier string number

      and class else false fun for if nil for
      print return super this true var while

      eof
    ].freeze

    attr_reader :type, :line, :lexeme, :literal

    def initialize(type, line, lexeme, literal = nil)
      raise ArgumentError, "Invalid token type: #{type}" unless TYPES.include? type
      raise ArgumentError, "Invalid line number: #{line}" unless line.positive?

      @type = type
      @line = line
      @lexeme = lexeme
      @literal = literal
    end

    def to_s
      [@type, @lexeme, @literal].compact.join " "
    end
  end
end
