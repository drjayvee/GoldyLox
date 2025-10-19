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
      until eof?
        @start = @current
        scan_token
      end

      add_token :eof
    end

    private

    def eof?
      @current == @source.length
    end

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

      when "!" then add_token match("=") ? :bang_equal    : :bang
      when "=" then add_token match("=") ? :equal_equal   : :equal
      when "<" then add_token match("=") ? :less_equal    : :less
      when ">" then add_token match("=") ? :greater_equal : :greater

      when "/"
        if match "/" # comment
          advance until peek == "\n" || eof?
        else
          add_token :slash
        end

      when " ", "\r", "\t" # ignore whitespace
      when "\n" then @line += 1

      when '"' then string

      else @errors << LexicalError.new("Unexpected character", @line)
      end
    end

    def string
      until peek == '"'
        if eof?
          @errors << LexicalError.new("Unterminated string", @line)
          return
        end

        @line += 1 if peek == "\n"
        advance
      end

      add_token :string, @source[@start + 1..@current - 1] # start and current are now at the start and end quotes
      advance # past closing `"`
    end

    def match(expected)
      return false if eof?
      return false if @source[@current] != expected

      @current += 1
      true
    end

    def peek
      eof? ? "\0" : @source[@current]
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
