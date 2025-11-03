# frozen_string_literal: true

require_relative "test_helper"

class InterpreterTest < Minitest::Test
  # @param expr GoldyLox::Expression | String
  # @return untyped
  def interpret(expr)
    if expr.is_a? String
      expr = (parser = GoldyLox::Parser.new(
        GoldyLox::Scanner.new(expr).scan_tokens
      )).parse

      raise "Parse error(s): #{parser.errors.join(". ")}" if expr.nil?
    end

    GoldyLox::Interpreter.new(expr).interpret
  end

  def test_literals
    [nil, true, false, 0, 1, "", "0", "hi"].each do |literal|
      assert literal == interpret(GoldyLox::Expression::Literal.new(literal))
    end
  end

  def test_unary
    assert_equal(-5, interpret("-5"))
    assert_equal 5, interpret("--5")

    assert_equal true, interpret("!false")
    assert_equal false, interpret("!true")
    assert_equal false, interpret("!!false")
    assert_equal true, interpret("!!true")
  end

  def test_grouping
    assert_equal 1, interpret("(1)")
    assert_equal true, interpret("(true)")
    assert_equal "yep", interpret("(\"yep\")")
    assert_nil interpret("((nil))")
  end

  def test_minus
    assert_equal 5, interpret("7 - 2")
    assert_equal(-5, interpret("2 - 7"))
    assert_equal(9, interpret("2 - -7"))
  end
end
