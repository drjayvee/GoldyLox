# frozen_string_literal: true

require_relative "test_helper"

class ExpressionTest < Minitest::Test
  class Bruh < GoldyLox::Expression; attrs :dude, :sweet; end

  # @param klass Class
  # @param methods Array[Symbol]
  def assert_class_methods(klass, methods)
    methods.each { assert klass.instance_methods(false).include?(it), "Expect class '#{klass}' to have method '#{it}'" }
  end

  # I'm not sure if I should even test attrs directly, but I wrote this while implementing,
  # so I'll keep this around for now.
  def test_attrs_helper
    attrs = { dude: "jessey", sweet: true }
    bro = Bruh.new(*attrs.values)

    attrs.each do |attr, val|
      assert bro.respond_to? attr
      assert_equal val, bro.send(attr)
    end
  end

  def test_class_methods
    assert_class_methods GoldyLox::Expression::Binary, %i[left operator right]
    assert_class_methods GoldyLox::Expression::Grouping, %i[expression]
    assert_class_methods GoldyLox::Expression::Literal, %i[value]
    assert_class_methods GoldyLox::Expression::Unary, %i[operator right]
  end

  def test_literal_type_assertion
    skip "RBS runtime type checking not enabled" unless defined? RBS::Test

    assert_raises RBS::Test::Tester::TypeError do
      GoldyLox::Expression::Literal.new true
    end
  end
end
