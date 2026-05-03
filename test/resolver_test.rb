# frozen_string_literal: true

require_relative "test_helper"

class ResolverTest < Minitest::Test
  class Interpreter
    attr_reader :locals

    def initialize
      @locals = {}
    end

    def resolve(expr, depth)
      @locals[expr] = depth
    end

    # @rbs name: String
    # @rbs return: Integer
    def depth_for(name)
      @locals.select { it.name.lexeme == name }.values.first
    end
  end

  def setup
    @interpreter = Interpreter.new
    @resolver = GoldyLox::Resolver.new @interpreter
  end

  def resolve(lox)
    @statements = GoldyLox::Parser.new(
      GoldyLox::Scanner.new(lox).scan_tokens
    ).parse

    @resolver.resolve_all @statements
  end

  def test_globals_are_not_resolved
    resolve <<~LOX
      var foo = "foo";
      fun func () {
        print foo;
      }
    LOX

    assert_empty @interpreter.locals
  end

  def test_block_local_is_resolved
    resolve <<~LOX
      {
        var foo = "foo";
        print foo;
      }
    LOX

    assert_equal 1, @interpreter.locals.size
    assert_equal 0, @interpreter.depth_for("foo")
  end

  def test_shadowed_variable
    resolve <<~LOX
      var foo = "foo";
      {
        var foo = "bar";
        print foo;
      }
    LOX

    assert_equal 1, @interpreter.locals.size
    assert_equal 0, @interpreter.depth_for("foo")
  end

  def test_preceding_declaration_semantics
    resolve <<~LOX
      {
        var foo = "foo";
        {
          print foo;
          var foo = "bar";
          print foo;
        }
      }
    LOX

    assert_equal 2, @interpreter.locals.size
    assert_equal(1, @interpreter.locals.values[0])
    assert_equal(0, @interpreter.locals.values[1])
  end

  def test_cannot_read_local_in_initializer
    assert_raises GoldyLox::Resolver::ResolutionError do
      resolve <<~LOX
        {
          var foo = foo;
        }
      LOX
    end

    assert_empty @interpreter.locals
  end

  def test_function_scope
    resolve <<~LOX
      fun func(foo) {
        print foo;
      }
    LOX

    assert_equal 1, @interpreter.locals.size
    assert_equal 1, @interpreter.depth_for("foo")
  end

  def test_nested_function_scope
    resolve <<~LOX
      fun func(foo) {
        fun funk(bar) {
          print foo + bar;
        }
        funk("bar");
      }
      func("foo");
    LOX

    assert_equal 3, @interpreter.locals.size
    assert_equal 3, @interpreter.depth_for("foo")  # Print
    assert_equal 0, @interpreter.depth_for("funk") # Call
    assert_equal 1, @interpreter.depth_for("bar")  # Print
  end
end
