# frozen_string_literal: true

module GoldyLox
  class Statement
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

    class Expression < Statement # :nodoc:
      attrs :expression
    end

    class Print < Statement # :nodoc:
      attrs :expression
    end
  end
end
