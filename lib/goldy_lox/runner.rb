# frozen_string_literal: true

module GoldyLox
  class Runner # :nodoc:
    def initialize(out = $stdout, err = $stderr)
      @out = out
      @err = err

      @printer = AstPrinter.new
      @interpreter = GoldyLox::Interpreter.new(@out)
    end

    def run(lox)
      tokens = (scanner = GoldyLox::Scanner.new(lox)).scan_tokens
      if scanner.errors.any?
        scanner.errors.each do |error|
          log_error error.message, error.line
        end
        return
      end

      begin
        last_token = tokens[-2] # last token _excluding_ :eof
        unless %i[semicolon right_brace].include?(last_token.type)
          tokens.insert(-2, GoldyLox::Token.new(:semicolon, last_token.line, ";")) # turn a single expression into an expression statement.
        end

        statements = GoldyLox::Parser.new(tokens).parse
      rescue Parser::ParseError => e
        log_error e.message, e.token.line
        return
      end

      statements.each { @err << "#{@printer.print(it)}\n" }

      begin
        if single_expression?(statements)
          log_result @interpreter.evaluate(statements.first.expression)
        else
          @interpreter.interpret statements
        end
      rescue Interpreter::InvalidOperandError => e
        log_error e.message, e.operator.line
      end
    end

    private

    def log_error(message, line)
      @out << "! #{message} (:#{line})\n"
    end

    def log_result(value)
      @out << "> #{value}"
    end

    def single_expression?(statements)
      statements.length == 1 && statements.first.is_a?(GoldyLox::Statement::Expression)
    end
  end
end
