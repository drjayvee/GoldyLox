# frozen_string_literal: true

module GoldyLox
  class Interpreter
    class InvalidOperandError < RuntimeError # :nodoc:
      attr_reader :operator, :value

      def initialize(operator, value)
        @operator = operator
        @value = value
        super("Invalid operand for #{operator.type}: #{value.inspect}")
      end
    end

    def initialize(out = $stdout)
      @out = out
    end

    def interpret(statements)
      statements.each { execute it }
    end

    def execute(statement)
      statement.accept self
    end

    def evaluate(expr)
      expr.accept self
    end

    def visit_expression(stmt)
      stmt.expression.accept self
    end

    def visit_print(stmt)
      @out << "#{stmt.expression.accept(self)}\n"
    end

    def visit_binary(expr)
      left = expr.left.accept self
      right = expr.right.accept self
      operator = expr.operator

      case operator.type
      when :minus
        assert_numeric_operands(operator, left, right)
        left - right
      when :plus
        # left operand's type is leading
        case left
        when String then raise InvalidOperandError.new(operator, right) unless right.is_a? String
        when Numeric then assert_numeric_operands(operator, right)
        else raise InvalidOperandError.new(operator, left)
        end

        left + right
      when :star
        assert_numeric_operands(operator, left, right)
        left * right
      when :slash
        assert_numeric_operands(operator, left, right)
        left / right
      when :equal_equal then left == right
      when :bang_equal then left != right
      when :greater then left > right
      when :greater_equal then left >= right
      when :less then left < right
      when :less_equal then left <= right
      else
        raise RuntimeError "Invalid operator"
      end
    end

    def visit_grouping(expr)
      expr.expression.accept self
    end

    def visit_literal(expr)
      expr.value
    end

    def visit_unary(expr)
      value = expr.right.accept(self)

      case expr.operator.type
      when :minus
        assert_numeric_operands(expr.operator, value)
        -value
      when :bang then !value # "Lox follows Ruby’s simple rule: false and nil are falsey, and everything else is truthy"
      else
        raise RuntimeError "Invalid operator"
      end
    end

    def visit_variable(expr)
      raise "Variables not yet implemented"
    end

    def assert_numeric_operands(operator, *operands)
      operands.each do |operand|
        raise InvalidOperandError.new(operator, operand) unless operand.is_a?(Numeric)
      end
    end
  end
end
