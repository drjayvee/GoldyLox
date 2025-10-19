# frozen_string_literal: true

require_relative "test_helper"

class ScannerTest < Minitest::Test
  def test_empty_source
    tokens = scan_tokens ""

    assert_equal 1, tokens.size
    assert_equal "eof ", tokens.last.to_s
  end

  def test_invalid_character
    scanner = GoldyLox::Scanner.new "#"
    scanner.scan_tokens

    assert_predicate scanner.errors, :any?
    assert_kind_of GoldyLox::Scanner::LexicalError, scanner.errors.first
    assert_equal "Unexpected character", scanner.errors.first.to_s
  end

  def test_multiple_errors
    scanner = GoldyLox::Scanner.new "##"
    scanner.scan_tokens

    assert_equal 2, scanner.errors.length
  end

  def test_braces
    scanner = GoldyLox::Scanner.new "(())"
    tokens = scanner.scan_tokens

    assert_equal(
      %i[left_paren left_paren right_paren right_paren],
      tokens[..-2].map(&:type) # -2 to ignore :eof
    )
  end

  def test_bang_equal_less_greater_and_equal
    {
      "!" => :bang,
      "=" => :equal,
      "<" => :less,
      ">" => :greater,
    }.each_pair do |lexeme, token_type|
      assert_equal(
        token_type,
        scan_tokens(lexeme).first.type
      )

      assert_equal(
        "#{token_type}_equal".to_sym,
        scan_tokens("#{lexeme}=").first.type
      )
    end
  end

  private

  def scan_tokens(source)
    GoldyLox::Scanner.new(source).scan_tokens
  end
end
