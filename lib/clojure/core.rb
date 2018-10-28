module Clojure
  class Core
    @@ctx = {}

    class << self
      def [] name
        @@ctx[name]
      end

      def define(name, value)
        @@ctx[name] = value
      end
    end

    define "+", ->(ctx, args) { args.reduce(:+) }
  end
end