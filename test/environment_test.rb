# frozen_string_literal: true

require_relative "test_helper"

class EnvironmentTest < Minitest::Test
  def setup
    @environment = GoldyLox::Environment.new

    @foo_name = "foo"
    @foo_token = identifier_token_for @foo_name
  end

  # @param name String
  # @return GoldyLox::Token
  def identifier_token_for(name)
    GoldyLox::Token.new :identifier, 1, name
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

  def test_assign_updates_value
    @environment.define @foo_name, true
    @environment.assign @foo_token, false

    assert_equal false, @environment.get(@foo_token)
  end

  def test_get_nested_variable
    outer = @environment
    outer.define @foo_name, true

    inner = GoldyLox::Environment.new outer

    assert_equal true, inner.get(@foo_token)
  end

  def test_get_shadowed_variable
    outer = @environment
    outer.define @foo_name, true

    inner = GoldyLox::Environment.new outer
    inner.define @foo_name, false

    assert_equal false, inner.get(@foo_token)
  end

  def test_update_nested_variable
    outer = @environment
    outer.define @foo_name, true

    inner = GoldyLox::Environment.new outer

    inner.assign @foo_token, nil

    assert_nil outer.get(@foo_token)
  end

  def test_update_shadowed_variable
    outer = @environment
    outer.define @foo_name, true

    inner = GoldyLox::Environment.new outer
    inner.define @foo_name, false

    inner.assign @foo_token, nil

    assert_equal nil, inner.get(@foo_token)
    assert_equal true, outer.get(@foo_token)
  end

  def test_get_raises_if_not_declared
    assert_raises GoldyLox::Environment::UndefinedVariableError, "Undefined variable '#{@foo_name}'" do
      @environment.get @foo_token
    end

    inner = GoldyLox::Environment.new @environment
    assert_raises GoldyLox::Environment::UndefinedVariableError, "Undefined variable '#{@foo_name}'" do
      inner.get @foo_token
    end
  end

  def test_assign_raises_if_not_declared
    assert_raises GoldyLox::Environment::UndefinedVariableError, "Undefined variable '#{@foo_name}'" do
      @environment.assign @foo_token, true
    end

    inner = GoldyLox::Environment.new @environment
    assert_raises GoldyLox::Environment::UndefinedVariableError, "Undefined variable '#{@foo_name}'" do
      inner.assign @foo_token, true
    end
  end
end
