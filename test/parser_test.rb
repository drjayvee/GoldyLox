# frozen_string_literal: true

require_relative "test_helper"

class ParserTest < Minitest::Test
  def setup
    @printer = GoldyLox::AstPrinter.new
  end

  # @param tokens Array[GoldyLox::Token]
  # @return GoldyLox::Parser
  def parser(tokens)
    tokens += [[:eof, tokens.last[1], ""]] # copy and push
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

  def test_block_statement
    # { true; print 5; };
    parser = self.parser [
      [:left_brace, 1, "{"],
      [:true, 2, "true"],
      [:semicolon, 2, ";"],
      [:print, 3, "print"],
      [:number, 3, "5", 5],
      [:semicolon, 3, ";"],
      [:right_brace, 4, "}"]
    ]

    statements = parser.parse

    assert_kind_of GoldyLox::Statement::Block, block = statements.first
    assert_equal 2, block.statements.size
    assert_kind_of GoldyLox::Statement::Expression, block.statements.first
    assert_kind_of GoldyLox::Statement::Print, block.statements[1]
  end

  def test_empty_block_statement
    parser = self.parser [
      [:left_brace, 1, "{"],
      [:right_brace, 1, "}"]
    ]
    statements = parser.parse

    assert_kind_of GoldyLox::Statement::Block, statements.first
    assert_empty statements.first.statements
  end

  def test_block_statement_raises_if_right_brace_missing
    parser = self.parser [
      [:left_brace, 1, "{"]
    ]

    assert_raises GoldyLox::Parser::ParseError, "Expect '}' after block." do
      parser.parse
    end
  end

  def test_var_statement
    tokens = [
      [:var, 1, "var"],
      [:identifier, 1, "foo"]
      # missing semicolon
    ]

    assert_raises(GoldyLox::Parser::ParseError) { parser(tokens).parse }

    # without initializer
    tokens << [:semicolon, 1, ";"]

    statements = parser(tokens).parse
    assert_equal 1, statements.size
    assert_kind_of GoldyLox::Statement::Var, statements.first
    assert_equal "foo", statements.first.name.lexeme
    assert_nil statements.first.initializer

    # with initializer
    tokens.insert(2, [:equal, 1, "="], [:number, 1, "123"])

    statements = parser(tokens).parse
    assert_equal 1, statements.size
    assert_kind_of GoldyLox::Statement::Var, statements.first
    assert_kind_of GoldyLox::Expression::Literal, statements.first.initializer

    # with initializer, but missing semicolon
    assert_raises(GoldyLox::Parser::ParseError) { parser(tokens[..-2]).parse }
  end

  def test_invalid_assignment_target
    # 1 = 1
    assert_raises "Invalid assignment target" do
      parse_expression [
        [:number, 1, "1", 1],
        [:equal, 1, "="],
        [:number, 1, "1", 1]
      ]
    end

    # (a) = 3
    assert_raises "Invalid assignment target" do
      parse_expression [
        [:left_paren, 1, "1"],
        [:identifier, 1, "a"],
        [:right_paren, 1, "1"],
        [:equal, 1, "="],
        [:number, 1, "3", 3]
      ]
    end
  end

  def test_assignment_expression
    # a = 1
    expr = parse_expression [
      [:identifier, 1, "a"],
      [:equal, 1, "="],
      [:number, 1, "1", 1]
    ]

    assert_kind_of GoldyLox::Expression::Assignment, expr
    assert_equal "a", expr.name.lexeme
    assert_kind_of GoldyLox::Expression::Literal, expr.value
  end

  def test_assignment_chain
    # a = b = 5 + 5
    expr = parse_expression [
      [:identifier, 1, "a"],
      [:equal, 1, "="],
      [:identifier, 1, "b"],
      [:equal, 1, "="],
      [:number, 1, "5", 5],
      [:plus, 1, "+"],
      [:number, 1, "5", 5]
    ]

    assert_kind_of GoldyLox::Expression::Assignment, expr

    # assignment is right-associative
    assert_equal "a", expr.name.lexeme
    assert_kind_of GoldyLox::Expression::Assignment, expr.value

    assert_equal "b", expr.value.name.lexeme
    assert_kind_of GoldyLox::Expression::Binary, expr.value.value

    assert_equal "(a = (b = (+ 5 5)))", @printer.print(expr)
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
