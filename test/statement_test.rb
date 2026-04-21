# frozen_string_literal: true

require_relative "test_helper"

class StatementTest < Minitest::Test
  class Bruh < GoldyLox::Statement; attrs :dude, :sweet; end

  # @param klass Class
  # @param methods Array[Symbol]
  def assert_class_methods(klass, methods)
    methods.each { assert_includes klass.instance_methods(false), it, "Expect class '#{klass}' to have method '#{it}'" }
  end

  def test_attrs_helper
    attrs = { dude: "jessey", sweet: true }
    bro = Bruh.new(*attrs.values)

    attrs.each do |attr, val|
      assert_respond_to bro, attr
      assert_equal val, bro.send(attr)
    end
  end

  def test_class_methods
    assert_class_methods GoldyLox::Statement::Expression, %i[expression]
    assert_class_methods GoldyLox::Statement::Print, %i[expression]
  end

  def test_expression_type_assertion
    skip "RBS runtime type checking not enabled" unless defined? RBS::Test

    assert_raises RBS::Test::Tester::TypeError do
      GoldyLox::Statement::Expression.new true
    end
  end
end
