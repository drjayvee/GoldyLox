# frozen_string_literal: true

module GoldyLox
  # The scanner reads Lox source and transforms it into a Token stream
  class Scanner
    # :nodoc:
    class LexicalError < StandardError
      attr_reader :line

      def initialize(message, line)
        super(message)
        @line = line
      end
    end

    attr_reader :errors

    def initialize(source)
      @source = source
      @start = @current = 0
      @line = 1
      @tokens = []
      @errors = []
    end

    def scan_tokens
      while @current < @source.length
        @start = @current
        scan_token
      end

      @tokens.push Token.new(:eof, @line, "")
    end

    private

    def scan_token
      char = advance

      case char
      when "(" then add_token :left_paren
      when ")" then add_token :right_paren
      when "{" then add_token :left_brace
      when "}" then add_token :right_brace
      when "," then add_token :comma
      when "." then add_token :dot
      when "-" then add_token :minus
      when "+" then add_token :plus
      when ";" then add_token :semicolon
      when "*" then add_token :star
      else @errors << LexicalError.new("Unexpected character", @line)
      end
    end

    def advance
      char = @source[@current]
      @current += 1
      char
    end

    def add_token(type, literal = nil)
      text = @source[@start..@current]
      @tokens << Token.new(type, @line, text, literal)
    end
  end
end
