# frozen_string_literal: true

module GoldyLox
  # See https://craftinginterpreters.com/representing-code.html#a-not-very-pretty-printer
  class AstPrinter
    def print(expr)
      expr.accept(self)
    end

    def visit_expression(stmt)
      parenthesize "expr", stmt.expression
    end

    def visit_print(stmt)
      parenthesize "print", stmt.expression
    end

    def visit_binary(expr)
      parenthesize expr.operator.lexeme, expr.left, expr.right
    end

    def visit_literal(expr)
      return "nil" if expr.value.nil?

      expr.value.to_s
    end

    def visit_grouping(expr)
      parenthesize "group", expr.expression
    end

    def visit_unary(expr)
      parenthesize expr.operator.lexeme, expr.right
    end

    private

    def parenthesize(name, *exprs)
      str = +"("
      str << name
      exprs.each do
        str << " "
        str << it.accept(self)
      end
      str << ")"
    end
  end
end
