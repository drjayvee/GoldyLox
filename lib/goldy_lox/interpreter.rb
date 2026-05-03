# frozen_string_literal: true

module GoldyLox
  class Interpreter
    class InvalidOperandError < RuntimeError
      attr_reader :operator, :value

      def initialize(operator, value)
        @operator = operator
        @value = value
        super("Invalid operand for #{operator.type}: #{value.inspect}")
      end
    end

    class Return < RuntimeError
      attr_reader :value

      def initialize(value)
        @value = value
        super()
      end
    end

    def initialize(out = $stdout)
      @out = out
      @globals = @environment = Environment.new
      @locals = {}

      @globals.define(
        "clock",
        NativeFunction.new(0) { Time.now.to_f }
      )
    end

    def interpret(statements)
      statements.each { execute it }
    end

    def execute(statement)
      statement.accept self
    end

    def execute_block(block, environment)
      previous_environment = @environment
      @environment = Environment.new environment
      interpret block.statements
    ensure
      @environment = previous_environment
    end

    def evaluate(expr)
      expr.accept self
    end

    def resolve(expr, depth)
      @locals[expr] = depth
    end

    # region _StatementVisitor

    def visit_block(stmt)
      execute_block stmt, Environment.new(@environment)
    end

    def visit_expression(stmt)
      stmt.expression.accept self
    end

    def visit_function(stmt)
      @environment.define(
        stmt.name.lexeme,
        LoxFunction.new(stmt, @environment)
      )
    end

    def visit_if(stmt)
      if evaluate(stmt.condition) # if the condition is truthy (Lox and Ruby agree on truthiness)
        stmt.then_branch.accept self
      elsif !stmt.else_branch.nil?
        stmt.else_branch.accept self
      end
    end

    def visit_print(stmt)
      @out << "#{stmt.expression.accept(self)}\n"
    end

    def visit_return(stmt)
      value = stmt.expression ? evaluate(stmt.expression) : nil

      raise Return.new(value) # rubocop:disable Style/RaiseArgs
    end

    def visit_var(stmt)
      value = if stmt.initializer.nil?
        nil
      else
        evaluate stmt.initializer
      end

      @environment.define stmt.name.lexeme, value
    end

    def visit_while(stmt)
      execute(stmt.body) while evaluate(stmt.condition)
    end

    # endregion

    # region _ExpressionVisitor

    def visit_assignment(expr)
      value = evaluate expr.value

      if (distance = @locals[expr])
        @environment.assign_at distance, expr.name, value
      else
        @globals.assign expr.name, value
      end

      value
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
        raise "Invalid operator"
      end
    end

    def visit_call(expr)
      callee = evaluate expr.callee # callee implements _Callable
      arguments = expr.arguments.map { evaluate it }

      raise "Can only call functions and classes." unless callee.respond_to?(:arity) && callee.respond_to?(:call)

      if (arguments_count = arguments.size) != (arity = callee.arity)
        raise "Expected #{arguments_count} arguments but got #{arity}."
      end

      callee.call(self, arguments)
    end

    def visit_grouping(expr)
      expr.expression.accept self
    end

    def visit_logical(expr)
      left_value = evaluate(expr.left)

      if expr.operator.type == :or
        return left_value if left_value
      else # must be :and
        return left_value unless left_value
      end

      evaluate(expr.right)
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
        raise "Invalid operator"
      end
    end

    def visit_variable(expr)
      lookup_variable expr.name, expr
    end

    # endregion

    private

    def assert_numeric_operands(operator, *operands)
      operands.each do |operand|
        raise InvalidOperandError.new(operator, operand) unless operand.is_a?(Numeric)
      end
    end

    def lookup_variable(name, expr)
      if (distance = @locals[expr])
        @environment.get_at distance, name.lexeme
      else
        @globals.get name
      end
    end
  end
end
