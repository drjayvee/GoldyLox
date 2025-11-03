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

  def test_comment
    assert_equal :eof, scan_tokens("// don't mind @me!").first.type
  end

  def test_slash
    assert_equal "slash /", scan_tokens("/").first.to_s
  end

  def test_whitespace
    tokens = scan_tokens " (\n\t) "

    assert_equal %i[left_paren right_paren eof], tokens.map(&:type)
  end

  def test_string_literal
    tokens = scan_tokens('"hello world"')

    assert_equal 2, tokens.size
    assert_equal :string, tokens.first.type
    assert_equal '"hello world"', tokens.first.lexeme
    assert_equal "hello world", tokens.first.literal

    assert_equal "yo", scan_tokens(" \"yo\" ").first.literal
  end

  def test_multiline_string_literal
    tokens = scan_tokens('"hello \nworld"')

    assert_equal 2, tokens.size
    assert_equal :string, tokens.first.type
  end

  def test_unterminated_string_literal
    scanner = GoldyLox::Scanner.new '"uh oh'
    scanner.scan_tokens

    refute_empty scanner.errors
    assert_equal "Unterminated string", scanner.errors.first.to_s
  end

  def test_number_literal
    tokens = scan_tokens "1337"

    assert_equal 2, tokens.size
    assert_equal :number, tokens.first.type
    assert_equal "1337", tokens.first.lexeme
    assert_equal 1337, tokens.first.literal

    assert_equal 1337, scan_tokens("\t1337 ").first.literal
  end

  def test_number_literal_with_digits
    tokens = scan_tokens "13.37"

    assert_equal 2, tokens.size
    assert_equal :number, tokens.first.type
    assert_equal "13.37", tokens.first.lexeme
    assert_equal 13.37, tokens.first.literal
  end

  def test_number_with_dot
    %w[1. 9.].each do |number_literal|
      scanner = GoldyLox::Scanner.new number_literal
      tokens = scanner.scan_tokens[..-2] # skip :eof

      assert_empty scanner.errors
      assert_equal 2, tokens.length
      assert_equal number_literal.to_f, tokens.first.literal
      assert_equal :dot, tokens[1].type
    end
  end

  def test_keyword
    %i[print this for true fun and return if super].each do |keyword|
      ["", " ", "  ", "\t"].each do |padding|
        tokens = scan_tokens(padding + keyword.to_s + padding)

        assert_equal 2, tokens.size
        assert_equal keyword, tokens.first.type
        assert_equal keyword.to_s, tokens.first.lexeme
      end
    end
  end

  def test_identifier
    %w[if0 superfun for_fun awesome sure_thing _].each do |identifier|
      ["", " ", "  ", "\t"].each do |padding|
        tokens = scan_tokens(padding + identifier.to_s + padding)

        assert_equal 2, tokens.size
        assert_equal :identifier, tokens.first.type
        assert_equal identifier, tokens.first.lexeme
      end
    end
  end

  def test_complex_script
    scanner = GoldyLox::Scanner.new %(
      class Breakfast {
        cook() {
          print "Eggs a-fryin'!";
        }

        serve(who) {
          print "Enjoy your breakfast, " + who + ".";
        }
      }

      var breakfast = Breakfast();
      print breakfast; // "Breakfast instance".
    )
    tokens = scanner.scan_tokens

    assert_empty scanner.errors
    assert_equal 36, tokens.size
  end

  private

  def scan_tokens(source)
    GoldyLox::Scanner.new(source).scan_tokens
  end
end
