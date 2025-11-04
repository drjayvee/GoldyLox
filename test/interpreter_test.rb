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

  def test_unary_minus
    assert_equal(-5, interpret("-5"))
    assert_equal 5, interpret("--5")

    %w[true false nil \"hello\"].each do |operand|
      assert_raises GoldyLox::Interpreter::InvalidOperandError do
        interpret "-#{operand}"
      end
    end
  end

  def test_unary_bang
    %w[false nil].each do |operand|
      assert_equal true, interpret("!#{operand}")
    end

    %w[true 0 1 \"0\" \"1\"].each do |operand|
      assert_equal false, interpret("!#{operand}")
    end

    assert_equal false, interpret("!!false")
    assert_equal true, interpret("!!true")
  end

  def test_grouping
    assert_equal 1, interpret("(1)")
    assert_equal true, interpret("(true)")
    assert_equal "yep", interpret("(\"yep\")")
    assert_nil interpret("((nil))")
  end

  def test_binary_minus
    assert_equal 5, interpret("7 - 2")
    assert_equal 5, interpret("5 - 0")
    assert_equal(-5, interpret("2 - 7"))
    assert_equal(5, interpret("2 - -3"))

    ["true - 1", "1 - true", "1 - false", "1 - nil", "1 - \"1\""].each do |expr|
      assert_raises(GoldyLox::Interpreter::InvalidOperandError) { interpret expr }
    end
  end

  def test_binary_plus
    assert_equal 5, interpret("3 + 2")
    assert_equal 5, interpret("5 + 0")
    assert_equal(-5, interpret("-2 + -3"))
    assert_equal(5, interpret("7 + -2"))

    assert_equal "hi", interpret("\"h\" + \"i\"")
    assert_equal "hi", interpret("\"\" + \"hi\"")

    ["true + 1", "1 + true", "1 + false", "1 + nil", "1 + \"1\"", "\"1\" + 1"].each do |expr|
      assert_raises(GoldyLox::Interpreter::InvalidOperandError) { interpret expr }
    end
  end

  def test_binary_star
    assert_equal 10, interpret("5 * 2")
    assert_equal 4.08, interpret("1.2 * 3.4")

    assert_raises GoldyLox::Interpreter::InvalidOperandError do
      interpret "5 * true"
    end
  end

  def test_binary_slash
    assert_equal 2, interpret("8 / 4")
    assert_equal 1.8, interpret("9 / 5")

    assert_raises GoldyLox::Interpreter::InvalidOperandError do
      interpret "5 / true"
    end
  end
end
