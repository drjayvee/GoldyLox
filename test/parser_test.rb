# frozen_string_literal: true

require_relative "test_helper"

class ParserTest < Minitest::Test
  def setup
    @printer = GoldyLox::AstPrinter.new
  end

  # @param tokens Array[GoldyLox::Token]
  # @return GoldyLox::Parser
  def parser(tokens)
    tokens << [:eof, tokens.last[1], ""]
    tokens = tokens.map do |token_args|
      GoldyLox::Token.new(*token_args)
    end

    GoldyLox::Parser.new(tokens)
  end

  # @param tokens Array[GoldyLox::Token]
  # @return GoldyLox::Expression
  # @raise GoldyLox::Parser::ParseError
  def parse_expression(tokens)
    tokens << [:semicolon, tokens.last[1], ";"]
    parser(tokens).parse.first.expression
  end

  def test_primary
    expr = parse_expression [[:number, 1, "1337", 1337]]

    assert_equal "1337", @printer.print(expr)
  end

  def test_equality
    expr = parse_expression [
      [:number, 1, "1337", 1337],
      [:equal_equal, 2, "=="],
      [:string, 3, "\"leet\"", "leet"]
    ]

    assert_equal "(== 1337 leet)", @printer.print(expr)
  end

  def test_term_sequence
    # 1 + 2 + 3
    expr = parse_expression [
      [:number, 1, "1", 1],
      [:plus, 1, "+"],
      [:number, 2, "2", 2],
      [:plus, 1, "+"],
      [:number, 3, "3", 3]
    ]

    assert_equal "(+ 1 (+ 2 3))", @printer.print(expr)
  end

  def test_factor_precedes_term
    # 1 + 2 * 3
    expr = parse_expression [
      [:number, 1, "1", 1],
      [:plus, 1, "+"],
      [:number, 2, "2", 2],
      [:star, 1, "*"],
      [:number, 3, "3", 3]
    ]

    assert_equal "(+ 1 (* 2 3))", @printer.print(expr)

    # 1 * 2 + 3
    expr = parse_expression [
      [:number, 1, "1", 1],
      [:star, 1, "*"],
      [:number, 2, "2", 2],
      [:plus, 1, "+"],
      [:number, 3, "3", 3]
    ]

    assert_equal "(+ (* 1 2) 3)", @printer.print(expr)
  end

  def test_unary_precedes_factor
    # 1 * -2
    expr = parse_expression [
      [:number, 1, "1", 1],
      [:star, 1, "*"],
      [:minus, 1, "-"],
      [:number, 2, "2", 2]
    ]

    assert_equal "(* 1 (- 2))", @printer.print(expr)
  end

  def test_recursive_unary
    # !!0
    expr = parse_expression [
      [:bang, 1, "!"],
      [:bang, 1, "!"],
      [:number, 1, "0", 0]
    ]

    assert_equal "(! (! 0))", @printer.print(expr)

    # --1
    expr = parse_expression [
      [:minus, 1, "-"],
      [:minus, 1, "-"],
      [:number, 1, "0", 1]
    ]

    assert_equal "(- (- 1))", @printer.print(expr)
  end

  def test_grouping_precedes_factor
    # (1 + 2) * 3
    expr = parse_expression [
      [:left_paren, 1, "("],
      [:number, 1, "1", 1],
      [:plus, 1, "+"],
      [:number, 2, "2", 2],
      [:right_paren, 1, ")"],
      [:star, 1, "*"],
      [:number, 3, "3", 3]
    ]

    assert_equal "(* (group (+ 1 2)) 3)", @printer.print(expr)
  end

  def test_store_unsynchronizable_parse_error
    parser = self.parser [
      [:minus, 1, "-"]
    ]

    assert_raises GoldyLox::Parser::ParseError, "Expect expression" do
      parser.parse
    end
  end

  def test_statement_without_semicolon
    parser = self.parser [
      [:number, 1, "1", 1]
    ]

    assert_raises GoldyLox::Parser::ParseError, "Expect ';' after expression" do
      parser.parse
    end
  end

  def test_expression_statement
    parser = self.parser [
      [:number, 1, "1", 1],
      [:semicolon, 1, ";"]
    ]
    statements = parser.parse

    assert_equal 1, statements.size
    assert_kind_of GoldyLox::Statement::Expression, statements.first
    assert_kind_of GoldyLox::Expression::Literal, statements.first.expression
  end

  def test_print_statement
    parser = self.parser [
      [:print, 1, "print"],
      [:number, 1, "true", 1],
      [:semicolon, 1, ";"]
    ]
    statements = parser.parse

    assert_equal 1, statements.size
    assert_kind_of GoldyLox::Statement::Print, statements.first
    assert_kind_of GoldyLox::Expression::Literal, statements.first.expression
  end

  def test_store_synchronizable_parse_error
    # (1
    parser = self.parser [
      [:left_paren, 1, "("],
      [:number, 2, "1", 1]
    ]

    assert_raises GoldyLox::Parser::ParseError, "Expect ')' after expression" do
      parser.parse
    end
  end
end
