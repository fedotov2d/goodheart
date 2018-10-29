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
    define "quote", ->(_ctx, args) { args.first }

    define "not", ->(_ctx, args) { not args }
    define "nil?", ->(_ctx, args) { args.first.nil? }

    define "and", ->(ctx, args) { args.map { |form| ctx.evaluate form }.all? }
    define "or", (lambda do |ctx, args|
      args.find { |form| !!ctx.evaluate(form) }
    end)

    define "if", (lambda do |ctx, args|
     clause, then_expr, else_expr = args
     ctx.evaluate(clause) ? then_expr : else_expr
    end)
    define "when", ->(ctx, args) { self["if"][ctx, [*args[0..1], nil]] }
    define "when-not", ->(ctx, args) { self["if"][ctx, [args[0], nil, args[1]]] }

    define "count", ->(_ctx, args) { (args[0] || []).length }
    define "get", ->(_ctx, args) { args[0][args[1]] || args[2] }

    define "map", (lambda do |ctx, args|
      fn, coll = args
      coll.map { |i| fn[ctx, [i]] }
    end)

    define "filter", (lambda do |ctx, args|
      fn, coll = args
      coll.select { |i| fn[ctx, [i]] }
    end)

    define "remove", (lambda do |ctx, args|
      fn, coll = args
      new_coll = coll.dup
      new_coll.delete_if { |i| fn[ctx, [i]] }
    end)

    define "def", (lambda do |ctx, args|
      ctx[args[0]] = ctx.evaluate args[1]
      "#{ctx["*ns*"]}/#{args[0]}"
    end)

    define "byebug", ->(ctx, args) { byebug }

    define "ns", ->(ctx, args) { self["def"][ctx, ["*ns*", ["quote", args[0]]]]; nil }

    define "fn", (lambda do |ctx, args|
      # TODO: poor implementation
      lambda do |_ctx, fn_args|
        params = args[0][1..-1].zip(fn_args)
        fn_ctx = ctx.merge(Hash[params])
        args[1..-1].map do |form|
          fn_ctx.evaluate form
        end.last
      end
    end)

    define "defn", ->(ctx, args) { self['def'].call(ctx, [args[0], self['fn'].call(ctx, args[1..-1])]) }
  end
end