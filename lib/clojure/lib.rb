module Clojure
  module Library

    def ns
      @@ns ||= {}
    end

    def [] name
      ns[name]
    end

    def dig name
      ns[name]
    end

    def define(name, value)
      ns[name] = value
    end
  end
end
