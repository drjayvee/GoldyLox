# frozen_string_literal: true

module GoldyLox
  class Expression
    def accept(visitor)
      class_name = self.class.name.split("::").last
      visitor.send "visit_#{class_name.downcase}", self
    end

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

    class Assignment < Expression
      attrs :name, :value
    end

    class Binary < Expression
      attrs :left, :operator, :right
    end

    class Call < Expression
      attrs :callee, :paren, :arguments
    end

    class Grouping < Expression
      attrs :expression
    end

    class Literal < Expression
      attrs :value
    end

    class Logical < Expression
      attrs :left, :operator, :right
    end

    class Unary < Expression
      attrs :operator, :right
    end

    class Variable < Expression
      attrs :name
    end
  end
end
