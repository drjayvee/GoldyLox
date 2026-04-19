# frozen_string_literal: true

module GoldyLox
  class Function # :nodoc:
    attr_reader :arity

    def initialize(arity, &block)
      @arity = arity
      @block = block
    end

    def call(_, arguments)
      @block.call(arguments)
    end
  end
end
