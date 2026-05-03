# frozen_string_literal: true

require_relative "test_helper"

class InterpreterTest < Minitest::Test
  def setup
    @out = []
    @interpreter = GoldyLox::Interpreter.new @out
  end

  # @param expr GoldyLox::Expression | String
  # @return untyped
  def evaluate(expr)
    if expr.is_a? String
      expr += ";"
      expr = (parser = GoldyLox::Parser.new(
        GoldyLox::Scanner.new(expr).scan_tokens
      )).parse.first.expression

      raise "Parse error(s): #{parser.errors.join(". ")}" if expr.nil?
    end

    @interpreter.evaluate expr
  end

  def interpret(lox)
    @out.clear

    statements = GoldyLox::Parser.new(
      GoldyLox::Scanner.new(lox).scan_tokens
    ).parse

    GoldyLox::Resolver.new(@interpreter).resolve_all(statements)

    @interpreter.interpret statements
  end

  def test_literals
    [nil, true, false, 0, 1, "", "0", "hi"].each do |literal|
      assert literal == evaluate(GoldyLox::Expression::Literal.new(literal)) # rubocop:disable Minitest/AssertEqual
    end
  end

  def test_logical_expression_value
    assert_equal 2, evaluate("1 and 2")
    assert_nil evaluate("nil and 2")
    assert_nil evaluate("1 and nil")
    refute evaluate("false and nil")

    assert_equal 1, evaluate("1 or 2")
    assert_equal 2, evaluate("nil or 2")
    assert_equal 1, evaluate("1 or nil")
    assert_nil evaluate("false or nil")
  end

  def test_logical_expressions_short_circuit_right
    # Using assignment expressions allows us to detect whether the right is evaluated at all.
    interpret "var foo = 1; false and (foo = 2); print foo;"
    assert_equal "1.0", @out.join.chomp

    interpret "var foo = 1; true or (foo = 2); print foo;"
    assert_equal "1.0", @out.join.chomp
  end

  def test_unary_minus
    assert_equal(-5, evaluate("-5"))
    assert_equal 5, evaluate("--5")

    %w[true false nil \"hello\"].each do |operand|
      assert_raises GoldyLox::Interpreter::InvalidOperandError do
        evaluate "-#{operand}"
      end
    end
  end

  def test_unary_bang
    %w[false nil].each do |operand|
      assert_equal true, evaluate("!#{operand}") # rubocop:disable Minitest/AssertTruthy
    end

    %w[true 0 1 \"0\" \"1\"].each do |operand|
      assert_equal false, evaluate("!#{operand}") # rubocop:disable Minitest/RefuteFalse
    end

    assert_equal false, evaluate("!!false") # rubocop:disable Minitest/RefuteFalse
    assert_equal true, evaluate("!!true") # rubocop:disable Minitest/AssertTruthy
  end

  def test_unary_with_invalid_operator
    assert_raises RuntimeError, "Invalid operator" do
      @interpreter.evaluate GoldyLox::Expression::Unary.new(
        GoldyLox::Token.new(:plus, 1, "+"),
        GoldyLox::Expression::Literal.new(1)
      )
    end
  end

  def test_grouping
    assert_equal 1, evaluate("(1)")
    assert_equal true, evaluate("(true)") # rubocop:disable Minitest/AssertTruthy
    assert_equal "yep", evaluate("(\"yep\")")
    assert_nil evaluate("((nil))")
  end

  def test_variable_statement_and_expression
    @interpreter.interpret [
      GoldyLox::Statement::Var.new(
        GoldyLox::Token.new(:identifier, 1, "foo"),
        GoldyLox::Expression::Literal.new(1337)
      )
    ]

    assert_equal 1337, evaluate("foo")
  end

  def test_assignment
    # define variable first
    @interpreter.interpret [
      GoldyLox::Statement::Var.new(
        GoldyLox::Token.new(:identifier, 1, "foo"),
        nil
      )
    ]

    # now assign new value
    assert_equal 1337, evaluate("foo = 1337") # expression evaluates to r-value...
    assert_equal 1337, evaluate("foo") # and updates the variable's value
  end

  def test_cannot_assign_to_undefined_target
    assert_raises GoldyLox::Environment::UndefinedVariableError, "Undefined variable 'foo'" do
      evaluate "foo = 1"
    end
  end

  def test_binary_minus
    assert_equal 5, evaluate("7 - 2")
    assert_equal 5, evaluate("5 - 0")
    assert_equal(-5, evaluate("2 - 7"))
    assert_equal(5, evaluate("2 - -3"))

    ["true - 1", "1 - true", "1 - false", "1 - nil", "1 - \"1\""].each do |expr|
      assert_raises(GoldyLox::Interpreter::InvalidOperandError) { evaluate expr }
    end
  end

  def test_binary_plus
    assert_equal 5, evaluate("3 + 2")
    assert_equal 5, evaluate("5 + 0")
    assert_equal(-5, evaluate("-2 + -3"))
    assert_equal(5, evaluate("7 + -2"))

    assert_equal "hi", evaluate("\"h\" + \"i\"")
    assert_equal "hi", evaluate("\"\" + \"hi\"")

    ["true + 1", "1 + true", "1 + false", "1 + nil", "1 + \"1\"", "\"1\" + 1"].each do |expr|
      assert_raises(GoldyLox::Interpreter::InvalidOperandError) { evaluate expr }
    end
  end

  def test_binary_with_invalid_operator
    assert_raises "Invalid operator" do
      @interpreter.evaluate GoldyLox::Expression::Binary.new(
        GoldyLox::Expression::Literal.new(1),
        GoldyLox::Token.new(:bang, 1, "+"),
        GoldyLox::Expression::Literal.new(1)
      )
    end
  end

  def test_binary_star
    assert_equal 10, evaluate("5 * 2")
    assert_equal 4.08, evaluate("1.2 * 3.4")

    assert_raises GoldyLox::Interpreter::InvalidOperandError do
      evaluate "5 * true"
    end
  end

  def test_binary_slash
    assert_equal 2, evaluate("8 / 4")
    assert_equal 1.8, evaluate("9 / 5")

    assert_raises GoldyLox::Interpreter::InvalidOperandError do
      evaluate "5 / true"
    end
  end

  def test_block_scope
    interpret <<~LOX
      var foo = "13";
      {
        var bar = "37";
        print foo + bar;
      }
    LOX

    assert_equal "1337", @out.join.chomp
  end

  def test_if_statement
    # test if condition and then branch
    interpret('if (true) print "yes";')

    assert_equal "yes", @out.join.chomp

    interpret('if (false) print "yes";')

    assert_empty @out

    # test else branch
    interpret('if (true) print "yes"; else print "no";')

    assert_equal "yes", @out.join.chomp

    interpret('if (false) print "yes"; else print "no";')

    assert_equal "no", @out.join.chomp
  end

  def test_while_statement
    # body isn't evaluated if condition is never true
    interpret('while (false) print "yes";')

    assert_empty @out

    # happy path
    interpret("var i = 0; while (i < 3) print (i = i + 1);")

    assert_equal "1.0\n2.0\n3.0\n", @out.join
  end

  def test_call_invalid_callee
    assert_raises RuntimeError, "Can only call functions and classes." do
      evaluate '"call me maybe"()'
    end

    assert_raises RuntimeError, "Can only call functions and classes." do
      evaluate '"clock"()'
    end
  end

  def test_call_arity
    assert_raises RuntimeError, "Expect 0 arguments but got 1" do
      evaluate "clock(true)"
    end

    # TODO: add more cases once we (fully) support functions
  end

  def test_clock
    Time.freeze do
      assert_equal Time.now.to_f, evaluate("clock()")
    end
  end

  def test_function_call
    # without params
    interpret <<~LOX
      fun print_sum1() { print 1337; }
      print_sum1();
    LOX

    assert_equal "1337.0", @out.join.chomp

    # with params
    interpret <<~LOX
      fun print_sum2(foo, bar) { print foo + bar; }
      print_sum2(1300, 37);
    LOX

    assert_equal "1337.0", @out.join.chomp

    # with block scope + param
    interpret <<~LOX
      var foo = 1300;
      fun print_sum3(bar) { print foo + bar; }
      print_sum3(37);
    LOX

    assert_equal "1337.0", @out.join.chomp
  end

  def test_recursive_function_call
    interpret <<~LOX
      fun count(n) {
        if (n > 1) count(n - 1);
        print n;
      }
      count(3);
    LOX

    assert_equal "1.0\n2.0\n3.0\n", @out.join
  end

  def test_nested_function
    interpret <<~LOX
      var foo = "foo";
      fun outer(bar) {
        fun inner(baz) {
          print foo + bar + baz;
        }
        inner("baz");
      }
      outer("bar");
    LOX

    assert_equal "foobarbaz", @out.join.chomp
  end

  def test_return
    interpret <<~LOX
      var foo = "foo";
      fun foo(bar) {
         if (bar) return "bar: " + bar;
         return;
      }
      print foo(nil);
      print foo("baz");
    LOX

    assert_equal "\nbar: baz\n", @out.join
  end

  def test_local_function_closure
    interpret <<~LOX
      fun makeCounter() {
        var i = 0;
        fun count() {
          i = i + 1;
          print i;
        }
        return count;
      }
      var counter = makeCounter();
      counter();
      counter();
    LOX

    assert_equal "1.0\n2.0", @out.join.chomp
  end

  def test_closure_resolution
    interpret <<~LOX
      var a = "global";
      {
        fun showA() {
          print a;
        }

        showA();
        var a = "block";
        showA();
      }
    LOX

    assert_equal "global\nglobal", @out.join.chomp
  end
end
