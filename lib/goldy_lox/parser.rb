# frozen_string_literal: true

module GoldyLox
  # See chapter 6
  class Parser
    class ParseError < RuntimeError # :nodoc:
      attr_reader :token

      def initialize(message, token)
        super(message)
        @token = token
      end
    end

    def initialize(tokens)
      @tokens = tokens
      @current = 0
    end

    # NOTE: this method is not at all final, but it does provide a hook for testing for the time being
    def parse
      expression
    end

    private

    # Rule
    #  expression -> equality
    def expression
      equality
    end

    # Rule
    #  equality → comparison ( ( "!=" | "==" ) comparison )* ;
    def equality
      expr = comparison

      while match?(:bang_equal, :equal_equal) do
        operator = previous
        right = comparison
        expr = Expression::Binary.new expr, operator, right
      end

      expr
    end

    # Rule
    #  comparison → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
    def comparison
      expr = term

      while match?(:greater, :greater_equal, :less, :less_equal) do
        operator = previous
        right = term
        expr = Expression::Binary.new expr, operator, right
      end

      expr
    end

    # Rule
    #  term -> factor ( ( "-" | "+" ) factor )* ;
    def term
      expr = factor

      while match?(:minus, :plus) do
        operator = previous
        expr = Expression::Binary.new expr, operator, term
      end

      expr
    end

    # Rule
    #  unary ( ( "/" | "*" ) unary )* ;
    def factor
      expr = unary

      while match?(:slash, :star) do
        operator = previous
        right = unary
        expr = Expression::Binary.new expr, operator, right
      end

      expr
    end

    # Rule
    #  unary -> ( "!" | "-" ) unary
    #        | unary
    def unary
      if match?(:bang, :minus)
        operator = previous
        right = unary
        return Expression::Unary.new operator, right
      end

      primary
    end

    # Rule
    #  primary -> NUMBER | STRING | "true" | "false" | "nil"
    #          | "(" expression ")" ;
    def primary
      return Expression::Literal.new(previous.literal) if match? :number, :string
      return Expression::Literal.new(true) if match? :true
      return Expression::Literal.new(false) if match? :false
      return Expression::Literal.new(nil) if match? :nil

      if match? :left_paren
        expr = expression
        consume(:right_paren, "Expect ')' after expression")
        Expression::Grouping.new expr
      end
    end

    # Token stream utilities

    def end?
      @current == @tokens.size
    end

    def match?(*token_types)
      token_types.each do|token_type|
        if check? token_type
          advance
          return true
        end
      end

      false
    end

    def consume(token_type, message)
      return advance if check? token_type

      error peek, message
    end

    def advance
      @current += 1 unless end?

      previous
    end

    def check?(token_type)
      return false if end?

      peek.type == token_type
    end

    def peek
      @tokens[@current]
    end

    def previous
      @tokens[@current - 1]
    end

    def error(token, message)
      # TODO: GoldyLox.error(token, message)
      ParseError.new message, token
    end
  end
end
