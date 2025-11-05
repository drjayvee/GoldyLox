# frozen_string_literal: true

module GoldyLox
  class Expression
    extend AttrsHelper

    def accept(visitor)
      class_name = self.class.name.split("::").last
      visitor.send "visit_#{class_name.downcase}", self
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
