module Clojure
  class Core
    extend Library

    define "+", ->(_ctx, args) { args.reduce(:+) }
    define "-", ->(_ctx, args) { args.reduce(:-) }
    define "*", ->(_ctx, args) { args.reduce(:*) }
    define "/", ->(_ctx, args) { args.reduce(:/) }

    define "=", ->(_ctx, args) { !!args.reduce { |x, y| x == y ? x : break } }
    define ">", ->(_ctx, args) { !!args.reduce { |x, y| x >  y ? x : break } }
    define "<", ->(_ctx, args) { !!args.reduce { |x, y| x <  y ? x : break } }

    define "vector", ->(_ctx, args) { Array[*args] }
    define "hash-map", ->(_ctx, args) { Hash[*args] }

    define "str", ->(_ctx, args) { args.map(&:to_s).join }
    define "quote", ->(_ctx, args) { args.first }

    define "not", ->(_ctx, args) { not args }
    define "nil?", ->(_ctx, args) { args.first.nil? }

    define "do", ->(_ctx, args) { args.map { |f| ctx.evaluate f } }

    define "subs", ->(ctx, args) { (ctx.evaluate(args[0]))[ctx.evaluate(args[1])..(ctx.evaluate(args[2]) || -1)] }

    define "let", (lambda do |ctx, forms|
      # skip "vector" from params
      bindings = forms[0][1..-1]
      lctx = ctx.dup
      bindings.each_slice(2) do |k, v|
        lctx[k] = lctx.evaluate(v)
      end
      forms[1..-1].map do |f|
        lctx.evaluate(f)
      end.last
    end)

    define "for", (lambda do |ctx, forms|
      head, expr, extra = *forms
      raise Exception, "Wrong number of args passed to: core/for" if extra
      key = head[1]
      col = ctx.evaluate head[2]
      col.map do |i|
        fctx = ctx.merge key => i
        fctx.evaluate expr
      end
    end)

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

    define "distinct", ->(_ctx, args) { (args[0] || []).uniq }

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

    define "merge", (lambda do |ctx, args|
      coll = ctx.evaluate args[0]
      args[1..-1].each do |arg|
        coll.merge! ctx.evaluate(arg)
      end
      coll
    end)

    define "assoc", (lambda do |ctx, args|
      coll = ctx.evaluate args[0]
      pairs = args[1..-1].map { |x| ctx.evaluate x }
      coll.merge(Hash[*pairs])
    end)

    define "first", (lambda do |ctx, args|
      args.first.first
    end)

    define "rest", (lambda do |ctx, args|
      args.first[1..-1]
    end)

    define "ns", (lambda do |ctx, args|
      self["def"][ctx, ["*ns*", ["quote", args[0]]]]
      if args[1] && args[1][0] == :require
        args[1][1..-1].each do |refer|
          ns = refer[1].to_sym
          binds = Hash[*refer[2..-1]]
          bindings = {}
          bindings[binds[:as]] = [ns] if binds[:as]
          if binds[:refer]
            binds[:refer][1..-1].each do |ref|
              bindings[ref] = [ns, ref]
            end
          end
          bindings.each do |k, v|
            ctx[k] = Clojure::Alias.new do
              -> { ctx.runtime.namespaces.dig(*v) }
            end
          end
        end
      end

      nil
    end)

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
