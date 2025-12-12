# frozen_string_literal: true

module GoldyLox
  # See https://craftinginterpreters.com/representing-code.html#a-not-very-pretty-printer
  class AstPrinter
    def print(expr)
      expr.accept(self)
    end

    def visit_block(stmt)
      str = +"{ "
      stmt.statements.each { str << print(it) }
      str << " }"
    end

    def visit_expression(stmt)
      parenthesize "expr", stmt.expression
    end

    def visit_if(stmt)
      str = +"(if #{print(stmt.condition)} #{print(stmt.then_branch)}"
      str << " #{print(stmt.else_branch)}" unless stmt.else_branch.nil?
      str << ")"
    end

    def visit_print(stmt)
      parenthesize "print", stmt.expression
    end

    def visit_var(stmt)
      str = +"(var #{stmt.name.lexeme}"
      str << " = #{stmt.initializer.accept(self)}" unless stmt.initializer.nil?
      str << ")"
    end

    def visit_assignment(expr)
      str = +"(#{expr.name.lexeme} = "
      str << expr.value.accept(self)
      str << ")"
    end

    def visit_binary(expr)
      parenthesize expr.operator.lexeme, expr.left, expr.right
    end

    def visit_literal(expr)
      return "nil" if expr.value.nil?

      expr.value.to_s
    end

    def visit_logical(expr)
      parenthesize expr.operator.type, expr.left, expr.right
    end

    def visit_grouping(expr)
      parenthesize "group", expr.expression
    end

    def visit_unary(expr)
      parenthesize expr.operator.lexeme, expr.right
    end

    def visit_variable(expr)
      "variable #{expr.name.lexeme}"
    end

    private

    def parenthesize(name, *exprs)
      str = +"("
      str << name.to_s
      exprs.each do
        str << " "
        str << it.accept(self)
      end
      str << ")"
    end
  end
end
