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

    # Rule
    #  declaration -> variableDeclaration
    #              | statement ;
    def declaration
      if match? :var
        var_declaration
      else
        statement
      end
    end

    # Rule
    #  variableDeclaration -> "var" IDENTIFIER ( "=" expression )? ";" ;
    def var_declaration
      name = consume :identifier, "Expect variable name."
      initializer = match?(:equal) ? expression : nil
      consume :semicolon, "Expect ';' after variable declaration."
      Statement::Var.new(name, initializer)
    end

    # Rule
    #  statement -> expressionStatement
    #            | printStatement ;
    def statement
      if match? :print
        print_statement
      else
        expression_statement
      end
    end

    # Rule
    #  printStatement -> "print" expression ";" ;
    def print_statement
      expr = expression
      consume :semicolon, "Expect ';' after expression."
      Statement::Print.new expr
    end

    # Rule
    #  expressionStatement -> expression ";" ;
    def expression_statement
      expr = expression
      consume :semicolon, "Expect ';' after expression."
      Statement::Expression.new expr
    end

    # Rule
    #  expression -> assignment ;
    def expression
      assignment
    end

    # Rule
    #  assignment -> IDENTIFIER "=" assignment
    #             | equality ;
    def assignment
      expr = equality

      if match? :equal
        equals = previous
        value = assignment # assignment is right-associative

        error(equals, "Invalid assignment target") unless expr.is_a? Expression::Variable

        return Expression::Assignment.new(expr.name, value)
      end

      expr
    end

    # Rule
    #  equality → comparison ( ( "!=" | "==" ) comparison )* ;
    def equality
      expr = comparison

      while match?(:bang_equal, :equal_equal)
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

      while match?(:greater, :greater_equal, :less, :less_equal)
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

      while match?(:minus, :plus)
        operator = previous
        expr = Expression::Binary.new expr, operator, term
      end

      expr
    end

    # Rule
    #  unary ( ( "/" | "*" ) unary )* ;
    def factor
      expr = unary

      while match?(:slash, :star)
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
    #  primary -> "true" | "false" | "nil"
    #          | NUMBER | STRING
    #          | "(" expression ")"
    #          | IDENTIFIER ;
    def primary
      return Expression::Literal.new(previous.literal) if match? :number, :string
      return Expression::Literal.new(true) if match? :true
      return Expression::Literal.new(false) if match? :false
      return Expression::Literal.new(nil) if match? :nil

      return Expression::Variable.new previous if match? :identifier

      if match? :left_paren
        expr = expression
        consume(:right_paren, "Expect ')' after expression")
        return Expression::Grouping.new expr
      end

      error(peek, "Expect expression")
    end

    # Token stream utilities

    def end?
      @current == @tokens.size
    end

    def match?(*token_types)
      token_types.each do |token_type|
        if check? token_type
          advance
          return true
        end
      end

      false
    end

    def consume(token_type, message)
      return advance if check? token_type

      error(peek, message)
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
