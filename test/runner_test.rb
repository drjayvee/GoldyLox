# frozen_string_literal: true

require_relative "test_helper"

class RunnerTest < Minitest::Test
  def setup
    @out = []
    @runner = GoldyLox::Runner.new @out
  end

  def test_scanner_error
    @runner.run "#"

    assert_equal ["! Unexpected character (:1)\n"], @out
  end

  def test_parser_error
    @runner.run "oops"

    assert_equal ["! Expect expression (:1)\n"], @out
  end

  def test_interpreter_error
    @runner.run "1 + nil;"

    assert_equal ["! Invalid operand for plus: nil (:1)\n"], @out
  end

  def test_happy_path
    @runner.run "(2 + 3) * 5;"

    assert_equal ["=> 25.0\n"], @out
  end
end
