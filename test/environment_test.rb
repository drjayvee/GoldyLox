# frozen_string_literal: true

require_relative "test_helper"

class EnvironmentTest < Minitest::Test
  def setup
    @environment = GoldyLox::Environment.new
  end

  # @param name String
  # @return GoldyLox::Token
  def identifier_token_for(name)
    GoldyLox::Token.new :identifier, 1, name
  end

  def test_get_raises_if_not_declared
    assert_raises GoldyLox::Environment::UndefinedVariableError, "Undefined variable 'foo'" do
      @environment.get identifier_token_for("foo")
    end
  end

  def test_get_returns_value_if_declared
    [true, nil, 1337, "yep"].each_with_index do |value, i|
      variable_name = "foo#{i}"
      identifier = identifier_token_for variable_name

      @environment.define variable_name, value

      value = @environment.get identifier
      if value.nil?
        assert_nil value
      else
        assert_equal value, @environment.get(identifier)
      end
    end
  end
end
