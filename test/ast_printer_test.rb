# frozen_string_literal: true

require_relative "test_helper"

class AstPrinterTest < Minitest::Test
  def setup
    @printer = GoldyLox::AstPrinter.new
  end

  def test_binary
    expr = GoldyLox::Expression::Binary.new(
      GoldyLox::Expression::Literal.new(13),
      GoldyLox::Token.new(:plus, 1, "+"),
      GoldyLox::Expression::Literal.new(37)
    )

    assert_equal "(+ 13 37)", @printer.print(expr)
  end

  def test_literal
    literal = GoldyLox::Expression::Literal.new "hi"

    assert_equal "hi", @printer.print(literal)
  end

  def test_grouping
    grouping = GoldyLox::Expression::Grouping.new(
      GoldyLox::Expression::Literal.new(123)
    )

    assert_equal "(group 123)", @printer.print(grouping)
  end

  def test_unary
    unary = GoldyLox::Expression::Unary.new(
      GoldyLox::Token.new(:plus, 1, "+"),
      GoldyLox::Expression::Literal.new("")
    )

    assert_equal "(+ )", @printer.print(unary)
  end
end
