module Clojure
  class Core < Clojure::Lib
    define "+", ->(ctx, args) { args.reduce(:+) }
  end
end