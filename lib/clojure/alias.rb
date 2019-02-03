module Clojure
  class Alias
    def initialize
      @lookup = yield
    end

    def lookup
      @lookup.call
    end
  end
end
