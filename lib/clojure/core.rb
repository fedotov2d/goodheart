module Clojure
  class Core < Clojure::Lib
    define "+", ->(_ctx, args) { args.reduce(:+) }
    define "-", ->(_ctx, args) { args.reduce(:-) }
    define "*", ->(_ctx, args) { args.reduce(:*) }
    define "/", ->(_ctx, args) { args.reduce(:/) }

    define "=", ->(_ctx, args) { !!args.reduce { |x,y| x == y ? x : break } }
    define ">", ->(_ctx, args) { !!args.reduce { |x,y| x >  y ? x : break } }
    define "<", ->(_ctx, args) { !!args.reduce { |x,y| x <  y ? x : break } }

    define "vector", ->(_ctx, args) { Array[*args] }
    define "hash-map", ->(_ctx, args) { Hash[*args] }

    define "str", ->(_ctx, args) { args.map(&:to_s).join }
    define "quote", ->(_ctx, args) { args }

    define "def", ->(ctx, args) { ctx[args[0]] = args[1] }

    define "fn", (lambda do |ctx, args|
      lambda do |_ctx, fn_args|
        params = args[0][1..-1].zip(fn_args)
        fn_ctx = ctx.merge(Hash[params])
        args[1..-1].map do |form|
          fn_ctx.evaluate form
        end.last
      end
    end)
  end
end