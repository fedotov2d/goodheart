module Clojure
  class Lib
    @@ns = {}

    class << self
      def [] name
        @@ns[name]
      end

      def define(name, value)
        @@ns[name] = value
      end
    end
  end
end