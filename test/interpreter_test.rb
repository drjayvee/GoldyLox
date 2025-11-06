# frozen_string_literal: true

require_relative "test_helper"

class InterpreterTest < Minitest::Test
  # @param expr GoldyLox::Expression | String
  # @return untyped
  def interpret_expression(expr)
    if expr.is_a? String
      expr += ";"
      expr = (parser = GoldyLox::Parser.new(
        GoldyLox::Scanner.new(expr).scan_tokens
      )).parse.first.expression

      raise "Parse error(s): #{parser.errors.join(". ")}" if expr.nil?
    end

    GoldyLox::Interpreter.new(expr).interpret
  end

  def test_literals
    [nil, true, false, 0, 1, "", "0", "hi"].each do |literal|
      assert literal == interpret_expression(GoldyLox::Expression::Literal.new(literal))
    end
  end

  def test_unary_minus
    assert_equal(-5, interpret_expression("-5"))
    assert_equal 5, interpret_expression("--5")

    %w[true false nil \"hello\"].each do |operand|
      assert_raises GoldyLox::Interpreter::InvalidOperandError do
        interpret_expression "-#{operand}"
      end
    end
  end

  def test_unary_bang
    %w[false nil].each do |operand|
      assert_equal true, interpret_expression("!#{operand}")
    end

    %w[true 0 1 \"0\" \"1\"].each do |operand|
      assert_equal false, interpret_expression("!#{operand}")
    end

    assert_equal false, interpret_expression("!!false")
    assert_equal true, interpret_expression("!!true")
  end

  def test_grouping
    assert_equal 1, interpret_expression("(1)")
    assert_equal true, interpret_expression("(true)")
    assert_equal "yep", interpret_expression("(\"yep\")")
    assert_nil interpret_expression("((nil))")
  end

  def test_binary_minus
    assert_equal 5, interpret_expression("7 - 2")
    assert_equal 5, interpret_expression("5 - 0")
    assert_equal(-5, interpret_expression("2 - 7"))
    assert_equal(5, interpret_expression("2 - -3"))

    ["true - 1", "1 - true", "1 - false", "1 - nil", "1 - \"1\""].each do |expr|
      assert_raises(GoldyLox::Interpreter::InvalidOperandError) { interpret_expression expr }
    end
  end

  def test_binary_plus
    assert_equal 5, interpret_expression("3 + 2")
    assert_equal 5, interpret_expression("5 + 0")
    assert_equal(-5, interpret_expression("-2 + -3"))
    assert_equal(5, interpret_expression("7 + -2"))

    assert_equal "hi", interpret_expression("\"h\" + \"i\"")
    assert_equal "hi", interpret_expression("\"\" + \"hi\"")

    ["true + 1", "1 + true", "1 + false", "1 + nil", "1 + \"1\"", "\"1\" + 1"].each do |expr|
      assert_raises(GoldyLox::Interpreter::InvalidOperandError) { interpret_expression expr }
    end
  end

  def test_binary_star
    assert_equal 10, interpret_expression("5 * 2")
    assert_equal 4.08, interpret_expression("1.2 * 3.4")

    assert_raises GoldyLox::Interpreter::InvalidOperandError do
      interpret_expression "5 * true"
    end
  end

  def test_binary_slash
    assert_equal 2, interpret_expression("8 / 4")
    assert_equal 1.8, interpret_expression("9 / 5")

    assert_raises GoldyLox::Interpreter::InvalidOperandError do
      interpret_expression "5 / true"
    end
  end
end
