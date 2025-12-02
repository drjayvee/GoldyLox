# frozen_string_literal: true

module GoldyLox
  class Statement # :nodoc:
    def accept(visitor)
      class_name = self.class.name.split("::").last
      visitor.send "visit_#{class_name.downcase}", self
    end

    # Copied from Expression.attrs because of
    # https://youtrack.jetbrains.com/issue/RUBY-34849
    def self.attrs(*attrs)
      attr_reader(*attrs)

      define_method :initialize do |*args|
        super()
        attrs.each_with_index do |attr, i|
          instance_variable_set "@#{attr}", args[i]
        end
      end
    end

    class Block < Statement # :nodoc:
      attrs :statements
    end

    class Expression < Statement # :nodoc:
      attrs :expression
    end

    class Print < Statement # :nodoc:
      attrs :expression
    end

    class Var < Statement # :nodoc:
      attrs :name, :initializer
    end
  end
end
