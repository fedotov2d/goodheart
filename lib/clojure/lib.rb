# frozen_string_literal: true

module Clojure
  module Library
    def ns
      @ns ||= {}
    end

    def [](name)
      ns[name]
    end

    def dig(name)
      ns[name]
    end

    def define(name, value)
      ns[name] = value
    end

    def define_macro(name, value)
      ns[name] = Macro.new(value)
    end
  end
end
