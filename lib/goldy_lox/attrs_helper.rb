# frozen_string_literal: true

module GoldyLox
  # It's tempting to add a helper to make it even easier to declare classes:
  #
  #   def self.klass(*attrs)
  #     Class.new(self) do
  #       self.attrs(*attrs)
  #     end
  #   end
  #   Unary = klass :operator, :right
  #
  # Unfortunately, classes created this way are excluded from RBS' runtime
  # assertions because TracePoint won't emit +:class+ events.
  module AttrsHelper
    # Adds readable attributes for the current class.
    def attrs(*attrs)
      attr_reader(*attrs)

      define_method :initialize do |*args|
        super()
        attrs.each_with_index do |attr, i|
          instance_variable_set "@#{attr}", args[i]
        end
      end
    end
  end
end
