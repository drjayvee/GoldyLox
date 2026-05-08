# frozen_string_literal: true

module GoldyLox
  class Resolver
    class ResolutionErrorBase < RuntimeError
      attr_reader :token

      def initialize(message, token = nil)
        super(message)
        @token = token
      end
    end

    class InvalidReturnError < ResolutionErrorBase; end
    class InvalidThisError < ResolutionErrorBase; end
    class ResolutionError < ResolutionErrorBase; end

    def initialize(interpreter)
      @interpreter = interpreter
      @scopes = []
      @current_function = :none
      @current_class = :none
    end

    def resolve_all(stmts)
      stmts.each { resolve it }
    end

    # region _StatementVisitor

    def visit_class(stmt)
      enclosing_class = @current_class
      @current_class = :class

      declare stmt.name
      define stmt.name

      if stmt.super_class
        if stmt.name.lexeme == stmt.super_class.name.lexeme
          raise ResolutionError.new("A class can't inherit from itself", stmt.super_class.name)
        end

        @current_class = :subclass

        resolve stmt.super_class

        begin_scope
        @scopes.last["super"] = true
      end

      begin_scope
      @scopes.last["this"] = true

      stmt.methods.each do |method|
        type = method.name.lexeme == "init" ? :initializer : :method
        resolve_function method, type
      end

      end_scope
      end_scope if stmt.super_class

      @current_class = enclosing_class
    end

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

      resolve_function(stmt, :function)
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
      unless %i[function method initializer].include? @current_function
        raise InvalidReturnError.new("Can only return from functions and methods.", stmt.keyword)
      end

      return unless stmt.expression

      if @current_function == :initializer # rubocop:ignore Style/IfUnlessModifier
        raise InvalidReturnError.new("Cannot return from initializer method.", stmt.keyword)
      end

      resolve stmt.expression
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

    def visit_get(expr)
      resolve expr.object
    end

    def visit_grouping(expr)
      resolve expr.expression
    end

    def visit_literal(_expr); end

    def visit_logical(expr)
      resolve expr.left
      resolve expr.right
    end

    def visit_set(expr)
      resolve expr.object
      resolve expr.value
    end

    def visit_super(expr)
      if @current_class == :none
        raise ResolutionError.new("Can't use 'super' outside of a class.", expr.keyword)
      elsif @current_class != :subclass
        raise ResolutionError.new("Can't use 'super' in a class with no superclass.", expr.keyword)
      end

      resolve_local expr, expr.keyword
    end

    def visit_this(expr)
      raise InvalidThisError.new("Can't use 'this' outside of a class.", expr.keyword) if @current_class == :none

      resolve_local expr, expr.keyword
    end

    def visit_unary(expr)
      resolve expr.right
    end

    def visit_variable(expr)
      if !@scopes.empty? && @scopes.last[expr.name.lexeme] == false
        raise ResolutionError.new("Can't read local variable in its own initializer.", expr.name)
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

    def resolve_function(stmt, type)
      current_function = @current_function
      @current_function = type

      begin_scope
      stmt.parameters.each { declare it; define it } # rubocop:disable Style/Semicolon
      resolve stmt.body # visit_block will create a new scope
      end_scope

      @current_function = current_function
    end
  end
end
