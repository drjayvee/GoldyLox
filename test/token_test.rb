# frozen_string_literal: true

require_relative "test_helper"

class TokenTest < Minitest::Test
  def test_invalid_token_type
    assert_raises ArgumentError do
      GoldyLox::Token.new :whoops, 1, ""
    end
  end

  def test_invalid_line_number
    assert_raises ArgumentError do
      GoldyLox::Token.new :fun, 0, ""
    end
  end

  def test_identifier
    token = GoldyLox::Token.new :identifier, 1, "foo"

    assert_equal :identifier, token.type
    assert_equal 1, token.line
    assert_equal "foo", token.lexeme
    assert_nil token.literal

    assert_equal "identifier foo", token.to_s
  end

  def test_string_literal
    token = GoldyLox::Token.new :string, 1234, "\"quite 'leet'\"", "quite 'leet'"

    assert_equal :string, token.type
    assert_equal 1234, token.line
    assert_equal "\"quite 'leet'\"", token.lexeme
    assert_equal "quite 'leet'", token.literal

    assert_equal "string \"quite 'leet'\" quite 'leet'", token.to_s
  end

  def test_number_literal
    token = GoldyLox::Token.new :number, 1234, "1337", 1337

    assert_equal :number, token.type
    assert_equal 1234, token.line
    assert_equal "1337", token.lexeme
    assert_equal 1337, token.literal

    assert_equal "number 1337 1337", token.to_s
  end

  def test_eof
    token = GoldyLox::Token.new :eof, 1, ""

    assert_equal :eof, token.type
    assert_equal 1, token.line
    assert_equal "", token.lexeme
    assert_nil token.literal

    assert_equal "eof ", token.to_s
  end
end
