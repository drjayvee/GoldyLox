# frozen_string_literal: true

module GoldyLox
  class Parser
    module Grammar # :nodoc:

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
      #            | forStatement
      #            | ifStatement
      #            | printStatement
      #            | whileStatement
      #            | block ;
      def statement
        if match? :for
          for_statement
        elsif match? :if
          if_statement
        elsif match? :print
          print_statement
        elsif match? :while
          while_statement
        elsif match? :left_brace
          Statement::Block.new block
        else
          expression_statement
        end
      end

      # Rule
      #  expressionStatement -> expression ";" ;
      def expression_statement
        expr = expression
        consume :semicolon, "Expect ';' after expression."
        Statement::Expression.new expr
      end

      # Rule
      #  forStatement -> "for" "(" ( var_declaration | expression_statement | ";" )
      #                  expression? ";"
      #                  expression? ")"
      #                  statement ;
      def for_statement
        consume :left_paren, "Expect '(' after for."

        initializer = if match? :semicolon
          nil
        elsif match? :var
          var_declaration
        else
          expression_statement
        end
        condition = match?(:semicolon) ? nil : expression
        consume :semicolon, "Expect ';' after loop condition."
        increment = match?(:semicolon) ? nil : expression
        consume :right_paren, "Expect ')' after for loop condition."
        body = statement

        # Desugar to while statement.
        if increment
          body = Statement::Block.new([
            body,
            Statement::Expression.new(increment)
          ])
        end

        condition ||= Expression::Literal.new(true)
        body = Statement::While.new(condition, body)

        body = Statement::Block.new([initializer, body]) if initializer

        body
      end

      # Rule
      #  ifStatement -> "if" "(" expression ")" statement
      #              ( "else" statement )? ;
      def if_statement
        consume :left_paren, "Expect '(' after if."
        condition = expression
        consume :right_paren, "Expect ')' after if condition."

        then_branch = statement
        else_branch = match?(:else) ? statement : nil

        Statement::If.new(condition, then_branch, else_branch)
      end

      # Rule
      #  printStatement -> "print" expression ";" ;
      def print_statement
        expr = expression
        consume :semicolon, "Expect ';' after expression."
        Statement::Print.new expr
      end

      # Rule
      #  while_statement -> "while" "(" expression ")" statement ;
      def while_statement
        consume :left_paren, "Expect '(' after while."
        condition = expression
        consume :right_paren, "Expect ')' after while condition."

        body = statement

        Statement::While.new(condition, body)
      end

      # Rule
      #  block -> "{" declaration* "}" ;
      def block
        statements = []
        statements << declaration until check?(:right_brace) || end?

        consume :right_brace, "Expect '}' after block."

        statements
      end

      # Rule
      #  expression -> assignment ;
      def expression
        assignment
      end

      # Rule
      #  assignment -> IDENTIFIER "=" assignment
      #             | logic_or ;
      def assignment
        expr = logical_or

        if match? :equal
          equals = previous
          value = assignment # assignment is right-associative

          error(equals, "Invalid assignment target") unless expr.is_a? Expression::Variable

          return Expression::Assignment.new(expr.name, value)
        end

        expr
      end

      # Rule
      #  logic_or -> logic_and ( "or" expression )* ;
      def logical_or
        expr = logical_and

        if match? :or
          operator = previous
          right = logical_and
          expr = Expression::Logical.new(expr, operator, right)
        end

        expr
      end

      # Rule
      #  logic_and -> equality ( "and" expression )* ;
      def logical_and
        expr = equality

        if match? :and
          operator = previous
          right = equality
          expr = Expression::Logical.new(expr, operator, right)
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
      #  factor -> unary ( ( "/" | "*" ) unary )* ;
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
      #        | primary ;
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
    end
  end
end
