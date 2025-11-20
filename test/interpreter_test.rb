# frozen_string_literal: true

require_relative "test_helper"

class InterpreterTest < Minitest::Test
  def setup
    @out = []
    @interpreter = GoldyLox::Interpreter.new @out
  end

  # @param expr GoldyLox::Expression | String
  # @return untyped
  def evaluate(expr)
    if expr.is_a? String
      expr += ";"
      expr = (parser = GoldyLox::Parser.new(
        GoldyLox::Scanner.new(expr).scan_tokens
      )).parse.first.expression

      raise "Parse error(s): #{parser.errors.join(". ")}" if expr.nil?
    end

    @interpreter.evaluate expr
  end

  def test_literals
    [nil, true, false, 0, 1, "", "0", "hi"].each do |literal|
      assert literal == evaluate(GoldyLox::Expression::Literal.new(literal))
    end
  end

  def test_unary_minus
    assert_equal(-5, evaluate("-5"))
    assert_equal 5, evaluate("--5")

    %w[true false nil \"hello\"].each do |operand|
      assert_raises GoldyLox::Interpreter::InvalidOperandError do
        evaluate "-#{operand}"
      end
    end
  end

  def test_unary_bang
    %w[false nil].each do |operand|
      assert_equal true, evaluate("!#{operand}")
    end

    %w[true 0 1 \"0\" \"1\"].each do |operand|
      assert_equal false, evaluate("!#{operand}")
    end

    assert_equal false, evaluate("!!false")
    assert_equal true, evaluate("!!true")
  end

  def test_grouping
    assert_equal 1, evaluate("(1)")
    assert_equal true, evaluate("(true)")
    assert_equal "yep", evaluate("(\"yep\")")
    assert_nil evaluate("((nil))")
  end

  def test_variable_expression
    assert_raises RuntimeError, "Variables not yet implemented" do
      evaluate "foo"
    end
  end

  def test_binary_minus
    assert_equal 5, evaluate("7 - 2")
    assert_equal 5, evaluate("5 - 0")
    assert_equal(-5, evaluate("2 - 7"))
    assert_equal(5, evaluate("2 - -3"))

    ["true - 1", "1 - true", "1 - false", "1 - nil", "1 - \"1\""].each do |expr|
      assert_raises(GoldyLox::Interpreter::InvalidOperandError) { evaluate expr }
    end
  end

  def test_binary_plus
    assert_equal 5, evaluate("3 + 2")
    assert_equal 5, evaluate("5 + 0")
    assert_equal(-5, evaluate("-2 + -3"))
    assert_equal(5, evaluate("7 + -2"))

    assert_equal "hi", evaluate("\"h\" + \"i\"")
    assert_equal "hi", evaluate("\"\" + \"hi\"")

    ["true + 1", "1 + true", "1 + false", "1 + nil", "1 + \"1\"", "\"1\" + 1"].each do |expr|
      assert_raises(GoldyLox::Interpreter::InvalidOperandError) { evaluate expr }
    end
  end

  def test_binary_star
    assert_equal 10, evaluate("5 * 2")
    assert_equal 4.08, evaluate("1.2 * 3.4")

    assert_raises GoldyLox::Interpreter::InvalidOperandError do
      evaluate "5 * true"
    end
  end

  def test_binary_slash
    assert_equal 2, evaluate("8 / 4")
    assert_equal 1.8, evaluate("9 / 5")

    assert_raises GoldyLox::Interpreter::InvalidOperandError do
      evaluate "5 / true"
    end
  end
end
