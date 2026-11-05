# frozen_string_literal: true

module Clojure
  class Macro
    def initialize(func)
      @fn = func
    end

    def expand(ctx, args)
      @fn.call(ctx, args)
    end

    def call(ctx, args)
      ctx.evaluate(expand(ctx, args))
    end

    alias [] call
  end
end
