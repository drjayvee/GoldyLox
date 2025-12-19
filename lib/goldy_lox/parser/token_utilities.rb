# frozen_string_literal: true

module GoldyLox
  class Parser
    module TokenUtilities # :nodoc:
      def end?
        @current == @tokens.size
      end

      def match?(*token_types)
        token_types.each do |token_type|
          if check? token_type
            advance
            return true
          end
        end

        false
      end

      def consume(token_type, message)
        return advance if check? token_type

        error(peek, message)
      end

      def advance
        @current += 1 unless end?

        previous
      end

      def check?(token_type)
        return false if end?

        peek.type == token_type
      end

      def peek
        @tokens[@current]
      end

      def previous
        @tokens[@current - 1]
      end
    end
  end
end
