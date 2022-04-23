# frozen_string_literal: true

module Clojure
  class Alias
    def initialize
      @lookup = yield
    end

    def lookup
      @lookup.call
    end

    def call(ctx, args)
      lookup.call ctx, args
    end
  end
end
