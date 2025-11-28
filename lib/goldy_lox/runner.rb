# frozen_string_literal: true

module GoldyLox
  class Runner # :nodoc:
    def initialize(out = $stdout)
      @out = out
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
        statements = GoldyLox::Parser.new(tokens).parse
      rescue Parser::ParseError => e
        log_error e.message, e.token.line
        return
      end

      begin
        GoldyLox::Interpreter.new(@out).interpret statements
      rescue Interpreter::InvalidOperandError => e
        log_error e.message, e.operator.line
      end
    end

    private

    def log_error(message, line)
      @out << "! #{message} (:#{line})\n"
    end
  end
end
