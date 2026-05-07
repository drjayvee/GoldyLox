# GoldyLox: an interpreter for Lox, written in Ruby

I'm following along with [Robert Nystrom's Crafting Interpreters](https://craftinginterpreters.com) to learn how to
write an interpreter (which still seems magical to me), as well as to learn (more) Ruby and RBS.

# Showcase

Below are a couple of examples to where the Ruby code is just so much more elegant and beautiful than Java.

These put a smile on my face when I wrote them. 😍

### Scanning until the end of the line or file
```java
while (peek() != '\n' && !isAtEnd()) advance();
```

```ruby
advance until peek == "\n" || eof?
```

The Ruby code reads just almost like plain English. Swapping `while` with `until` to flip the condition makes it
crystal clear.

### Resolving a variable's depth
```java
private void resolveLocal(Expr expr, Token name) {
  for (int i = scopes.size() - 1; i >= 0; i--) {
    if (scopes.get(i).containsKey(name.lexeme)) {
      interpreter.resolve(expr, scopes.size() - 1 - i);
      return;
    }
  }
}
```

```ruby
def resolve_local(expr, name)
  @scopes.reverse_each.with_index do |scope, i|
    if scope.key? name.lexeme
      @interpreter.resolve(expr, i)
      return
    end
  end
end
```

Using `reverse_each` makes the intent immediately clear. There's also no need for `scopes.get(i)`.

Replacing `scopes.size() - 1 - i` with just `i` avoids any chance for off-by-one errors.

### Interpreting a call expressions
```java
@Override
public Void visitCallExpr(Expr.Call expr) {
  resolve(expr.callee);
  
  for (Expr argument : expr.arguments) {
    resolve(argument);
  }
  
  return null;
}
```

```ruby
def visit_call(expr)
  resolve expr.callee
  expr.arguments.each { resolve it }
end
```

I rest my case. ☺️
