# frozen_string_literal: true

module GoldyLox
  class Interpreter
    def initialize(expression)
      @expression = expression
    end

    def interpret
      @expression.accept self
    end

    def visit_binary(expr)
      left = expr.left.accept self
      right = expr.right.accept self

      case expr.operator.type
      when :minus then left - right
      when :plus then left + right
      when :star then left * right
      when :slash then left / right
      when :equal_equal then left == right
      when :bang_equal then left != right
      when :greater then left > right
      when :greater_equal then left >= right
      when :less then left < right
      when :less_equal then left <= right
      else raise RuntimeError "Invalid operator"
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
      when :minus then -value
      when :bang then !value
      else raise RuntimeError "Invalid operator"
      end
    end
  end
end
