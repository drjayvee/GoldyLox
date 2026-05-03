# frozen_string_literal: true

module GoldyLox
  class Resolver
    class ResolutionError < RuntimeError; end

    def initialize(interpreter)
      @interpreter = interpreter
      @scopes = []
    end

    def resolve_all(stmts)
      stmts.each { resolve it }
    end

    # region _StatementVisitor

    def visit_block(stmt)
      begin_scope
      stmt.statements.each { resolve it }
      end_scope
    end

    def visit_expression(stmt)
      resolve stmt.expression
    end

    def visit_function(stmt)
      declare stmt.name
      define stmt.name

      begin_scope
      stmt.parameters.each { declare it; define it } # rubocop:disable Style/Semicolon
      resolve stmt.body # visit_block will create a new scope
      end_scope
    end

    def visit_if(stmt)
      resolve stmt.condition
      resolve stmt.then_branch
      resolve stmt.else_branch if stmt.else_branch
    end

    def visit_print(stmt)
      resolve stmt.expression
    end

    def visit_return(stmt)
      resolve stmt.expression if stmt.expression
    end

    def visit_var(stmt)
      declare(stmt.name)
      resolve stmt.initializer if stmt.initializer
      define(stmt.name)
    end

    def visit_while(stmt)
      resolve stmt.condition
      resolve stmt.body
    end

    # endregion

    # region _ExpressionVisitor

    def visit_assignment(expr)
      resolve expr.value
      resolve_local expr, expr.name
    end

    def visit_binary(expr)
      resolve expr.left
      resolve expr.right
    end

    def visit_call(expr)
      resolve expr.callee
      expr.arguments.each { resolve it }
    end

    def visit_grouping(expr)
      resolve expr.expression
    end

    def visit_literal(_expr); end

    def visit_logical(expr)
      resolve expr.left
      resolve expr.right
    end

    def visit_unary(expr)
      resolve expr.right
    end

    def visit_variable(expr)
      if !@scopes.empty? && @scopes.last[expr.name.lexeme] == false
        raise ResolutionError, "Can't read local variable in its own initializer."
      end

      resolve_local expr, expr.name
    end

    # endregion

    private

    def begin_scope
      @scopes.push({})
    end

    def end_scope
      @scopes.pop
    end

    def declare(name)
      return if @scopes.empty?

      @scopes.last[name.lexeme] = false
    end

    def define(name)
      return if @scopes.empty?

      @scopes.last[name.lexeme] = true
    end

    def resolve(expr_or_stmt)
      expr_or_stmt.accept self
    end

    def resolve_local(expr, name)
      @scopes.reverse_each.with_index do |scope, i|
        if scope.key? name.lexeme
          @interpreter.resolve(expr, i)
          break # RuboCop doesn't like return, but that's the intent here
        end
      end
    end
  end
end
