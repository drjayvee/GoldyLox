# frozen_string_literal: true

module GoldyLox
  class Statement
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

    class Block < Statement
      attrs :statements
    end

    class Expression < Statement
      attrs :expression
    end

    class Function < Statement
      attrs :name, :parameters, :body
    end

    class If < Statement
      attrs :condition, :then_branch, :else_branch
    end

    class Print < Statement
      attrs :expression
    end

    class Return < Statement
      attrs :keyword, :expression
    end

    class While < Statement
      attrs :condition, :body
    end

    class Var < Statement
      attrs :name, :initializer
    end
  end
end
