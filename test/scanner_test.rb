# frozen_string_literal: true

require_relative "test_helper"

class ScannerTest < Minitest::Test
  def test_empty_source
    scanner = GoldyLox::Scanner.new ""
    tokens = scanner.scan_tokens

    assert_equal 1, tokens.size
    assert_equal "eof ", tokens.last.to_s
  end

  def test_braces
    scanner = GoldyLox::Scanner.new "(())"
    tokens = scanner.scan_tokens

    assert_equal(
      %i[left_paren left_paren right_paren right_paren],
      tokens[..-2].map(&:type) # -2 to ignore :eof
    )
  end
end
