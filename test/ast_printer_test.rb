# frozen_string_literal: true

require_relative "test_helper"

class AstPrinterTest < Minitest::Test
  def setup
    @printer = GoldyLox::AstPrinter.new
  end

  def test_assignment_expression
    # foo = -1
    expr = GoldyLox::Expression::Assignment.new(
      GoldyLox::Token.new(:identifier, 1, "foo"),
      GoldyLox::Expression::Unary.new(
        GoldyLox::Token.new(:minus, 1, "-"),
        GoldyLox::Expression::Literal.new(1)
      )
    )

    assert_equal "(foo = (- 1))", @printer.print(expr)
  end

  def test_binary_expression
    expr = GoldyLox::Expression::Binary.new(
      GoldyLox::Expression::Literal.new(13),
      GoldyLox::Token.new(:plus, 1, "+"),
      GoldyLox::Expression::Literal.new(37)
    )

    assert_equal "(+ 13 37)", @printer.print(expr)
  end

  def test_literal_expression
    { "hi" => "hi", true => "true", false => "false", nil => "nil" }.each do |value, string|
      literal = GoldyLox::Expression::Literal.new value

      assert_equal string, @printer.print(literal)
    end

    def visit_while(stmt)
      "(while #{print(stmt.condition)} #{print(stmt.body)})"
    end
  end

  def test_logical_expression
    # 1 or 2 and 3
    logical = GoldyLox::Expression::Logical.new(
      GoldyLox::Expression::Literal.new(1),
      GoldyLox::Token.new(:or, 1, "or"),
      GoldyLox::Expression::Logical.new(
        GoldyLox::Expression::Literal.new(2),
        GoldyLox::Token.new(:and, 1, "and"),
        GoldyLox::Expression::Literal.new(3)
      )
    )

    assert_equal "(or 1 (and 2 3))", @printer.print(logical)
  end

  def test_grouping_expression
    grouping = GoldyLox::Expression::Grouping.new(
      GoldyLox::Expression::Literal.new(123)
    )

    assert_equal "(group 123)", @printer.print(grouping)
  end

  def test_unary_expression
    unary = GoldyLox::Expression::Unary.new(
      GoldyLox::Token.new(:plus, 1, "+"),
      GoldyLox::Expression::Literal.new("")
    )

    assert_equal "(+ )", @printer.print(unary)
  end

  def test_variable_expression
    variable = GoldyLox::Expression::Variable.new(
      GoldyLox::Token.new(:identifier, 1, "foo")
    )

    assert_equal "variable foo", @printer.print(variable)
  end

  def test_expression_statement
    statement = GoldyLox::Statement::Expression.new(
      GoldyLox::Expression::Literal.new(123)
    )

    assert_equal "(expr 123)", @printer.print(statement)
  end

  def test_if_statement
    # if without else: `if (true) print "yes";`
    statement = GoldyLox::Statement::If.new(
      GoldyLox::Expression::Literal.new(true),
      GoldyLox::Statement::Print.new(
        GoldyLox::Expression::Literal.new("yes")
      ),
      nil
    )

    assert_equal "(if true (print yes))", @printer.print(statement)

    # if with else: `if (foo > 0) print "yes"; else print "no";`
    statement = GoldyLox::Statement::If.new(
      GoldyLox::Expression::Binary.new(
        GoldyLox::Expression::Variable.new(
          GoldyLox::Token.new(:identifier, 1, "foo")
        ),
        GoldyLox::Token.new(:greater, 1, ">"),
        GoldyLox::Expression::Literal.new(0)
      ),
      GoldyLox::Statement::Print.new(
        GoldyLox::Expression::Literal.new("yes")
      ),
      GoldyLox::Statement::Print.new(
        GoldyLox::Expression::Literal.new("no")
      )
    )

    assert_equal "(if (> variable foo 0) (print yes) (print no))", @printer.print(statement)
  end

  def test_print_statement
    statement = GoldyLox::Statement::Print.new(
      GoldyLox::Expression::Literal.new(123)
    )

    assert_equal "(print 123)", @printer.print(statement)
  end

  def test_block_statement
    statement = GoldyLox::Statement::Block.new [
      GoldyLox::Statement::Expression.new(
        GoldyLox::Expression::Literal.new(123)
      ),
      GoldyLox::Statement::Print.new(
        GoldyLox::Expression::Literal.new("foo")
      )
    ]

    assert_equal "{ (expr 123)(print foo) }", @printer.print(statement)
  end

  def test_var_statement
    # without initializer: `var foo`
    var = GoldyLox::Statement::Var.new(
      GoldyLox::Token.new(:identifier, 1, "foo"),
      nil
    )

    assert_equal "(var foo)", @printer.print(var)

    # with initializer: `var foo = true`
    var = GoldyLox::Statement::Var.new(
      GoldyLox::Token.new(:identifier, 1, "foo"),
      GoldyLox::Expression::Literal.new(true)
    )

    assert_equal "(var foo = true)", @printer.print(var)
  end

  def test_while_statement
    # while (foo > 0) print foo;
    statement = GoldyLox::Statement::While.new(
      GoldyLox::Expression::Binary.new(
        GoldyLox::Expression::Variable.new(
          GoldyLox::Token.new(:identifier, 1, "foo")
        ),
        GoldyLox::Token.new(:greater, 1, ">"),
        GoldyLox::Expression::Literal.new(0)
      ),
      GoldyLox::Statement::Print.new(
        GoldyLox::Expression::Variable.new(
          GoldyLox::Token.new(:identifier, 1, "foo")
        )
      )
    )

    assert_equal "(while (> variable foo 0) (print variable foo))", @printer.print(statement)
  end
end
