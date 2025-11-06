# frozen_string_literal: true

module GoldyLox
  class Runner
    def initialize(out = $stdout)
      @out = out
    end

    def run(lox)
      tokens = (scanner = GoldyLox::Scanner.new(lox)).scan_tokens
      if scanner.errors.any?
        scanner.errors.each { log_error it.message, it.line }
        return
      end

      begin
        expr = GoldyLox::Parser.new(tokens).parse.first
      rescue Parser::ParseError => e
        log_error e.message, e.token.line
        return
      end

      begin
        value = GoldyLox::Interpreter.new(expr).interpret
      rescue Interpreter::InvalidOperandError => e
        log_error e.message, e.operator.line
        return
      end

      log_result value
    end

    private

    def log_error(message, line)
      @out << "! #{message} (:#{line})\n"
    end

    def log_result(result)
      @out << "=> #{result}\n"
    end
  end
end
