# frozen_string_literal: true

module GoldyLox
  class Expression
    # Adds readable attributes for the current class.
    #
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
    def self.attrs(*attrs)
      attr_reader(*attrs)

      define_method :initialize do |*args|
        super()
        attrs.each_with_index do |attr, i|
          instance_variable_set "@#{attr}", args[i]
        end
      end
    end

    class Binary < Expression # :nodoc:
      attrs :left, :operator, :right
    end

    class Grouping < Expression # :nodoc:
      attrs :expression
    end

    class Literal < Expression # :nodoc:
      attrs :value
    end

    class Unary < Expression # :nodoc:
      attrs :operator, :right
    end
  end
end
