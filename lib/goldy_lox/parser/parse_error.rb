# frozen_string_literal: true

module GoldyLox
  class Parser
    class ParseError < RuntimeError # :nodoc:
      attr_reader :token

      def initialize(message, token)
        super(message)
        @token = token
      end
    end
  end
end
