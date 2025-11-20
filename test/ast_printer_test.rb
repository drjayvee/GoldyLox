# frozen_string_literal: true

require_relative "test_helper"

class AstPrinterTest < Minitest::Test
  def setup
    @printer = GoldyLox::AstPrinter.new
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

  def test_variable
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

  def test_print_statement
    statement = GoldyLox::Statement::Print.new(
      GoldyLox::Expression::Literal.new(123)
    )

    assert_equal "(print 123)", @printer.print(statement)
  end
end
