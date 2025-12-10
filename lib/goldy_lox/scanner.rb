# frozen_string_literal: true

module GoldyLox
  # The scanner reads Lox source and transforms it into a Token stream
  class Scanner
    ALPHA_REGEX = /[a-zA-Z_]/
    DIGITS_RANGE = "0".."9"

    KEYWORDS = %i[and class else false fun for if nil or print return super this true var while].freeze

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

      when '"' then string_literal
      when DIGITS_RANGE then number_literal
      when ALPHA_REGEX then identifier

      else @errors << LexicalError.new("Unexpected character", @line)
      end
    end

    def string_literal
      until peek == '"'
        if eof?
          @errors << LexicalError.new("Unterminated string", @line)
          return
        end

        @line += 1 if peek == "\n"
        advance
      end

      advance # past closing `"`
      add_token :string, @source[@start + 1...@current - 1] # start and current are now at the start and end quotes
    end

    def number_literal
      advance while digit?(peek)

      if peek == "." && digit?(peek_next)
        advance # consume the "."

        advance while digit?(peek)
      end

      add_token :number, @source[@start...@current].to_f
    end

    def identifier
      advance while alpha?(peek) || digit?(peek)

      text = @source[@start...@current]
      token_type = KEYWORDS.include?(text.to_sym) ? text.to_sym : :identifier

      add_token token_type
    end

    def alpha?(char)
      ALPHA_REGEX.match? char
    end

    def digit?(char)
      DIGITS_RANGE.include?(char)
    end

    def match(expected)
      return false if eof?
      return false if @source[@current] != expected

      @current += 1
      true
    end

    def peek
      @source[@current] || "\0"
    end

    def peek_next
      @source[@current + 1] || "\0"
    end

    def advance
      char = @source[@current]
      @current += 1
      char
    end

    def add_token(type, literal = nil)
      text = @source[@start...@current]
      @tokens << Token.new(type, @line, text, literal)
    end
  end
end
