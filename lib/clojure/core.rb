# frozen_string_literal: true

module Clojure
  class Core
    extend Library

    define "+", ->(_ctx, args) { args.inject(:+) }
    define "-", ->(_ctx, args) { args.inject(:-) }
    define "*", ->(_ctx, args) { args.inject(:*) }
    define "/", ->(_ctx, args) { args.inject(:/) }

    define "=", ->(_ctx, args) { !args.inject {|x, y| x == y ? x : break }.nil? }
    define ">", ->(_ctx, args) { !args.inject {|x, y| x >  y ? x : break }.nil? }
    define "<", ->(_ctx, args) { !args.inject {|x, y| x <  y ? x : break }.nil? }

    define "vector", ->(_ctx, args) { [*args] }
    define "hash-map", ->(_ctx, args) { Hash[*args] }

    define "str", ->(_ctx, args) { args.join }
    define "quote", ->(_ctx, args) { args.first }

    define "not", ->(_ctx, args) { !args.first }
    define "nil?", ->(_ctx, args) { args.first.nil? }

    define "do", ->(ctx, args) { args.map {|f| ctx.evaluate f }.last }

    define "subs", ->(ctx, args) { ctx.evaluate(args[0])[ctx.evaluate(args[1])..(ctx.evaluate(args[2]) || -1)] }

    define "let", (lambda do |ctx, forms|
      # skip "vector" from params
      bindings = forms[0][1..]
      lctx = ctx.dup
      bindings.each_slice(2) do |k, v|
        lctx[k] = lctx.evaluate(v)
      end
      forms[1..].map do |f|
        lctx.evaluate(f)
      end.last
    end)

    define "for", (lambda do |ctx, forms|
      head, expr, extra = *forms
      raise StandardError, "Wrong number of args passed to: core/for" if extra

      key = head[1]
      col = ctx.evaluate head[2]
      col.map do |i|
        fctx = ctx.dup
        fctx[key] = i
        fctx.evaluate expr
      end
    end)

    define "and", (lambda do |ctx, args|
      result = true
      args.each do |form|
        result = ctx.evaluate(form)
        return result unless result
      end
      result
    end)

    define "or", (lambda do |ctx, args|
      result = nil
      args.each do |form|
        result = ctx.evaluate(form)
        return result if result
      end
      result
    end)

    define "if", (lambda do |ctx, args|
      clause, then_expr, else_expr = args
      ctx.evaluate(clause) ? ctx.evaluate(then_expr) : ctx.evaluate(else_expr)
    end)

    define "when", (lambda do |ctx, args|
      clause, *body = args
      self["do"][ctx, body] if ctx.evaluate(clause)
    end)

    define "when-not", (lambda do |ctx, args|
      clause, *body = args
      self["do"][ctx, body] unless ctx.evaluate(clause)
    end)

    define "count", ->(_ctx, args) { (args[0] || []).length }
    define "get", ->(_ctx, args) { args[0][args[1]] || args[2] }

    define "map", (lambda do |ctx, args|
      fn, coll = args
      coll.map {|i| fn[ctx, [i]] }
    end)

    define "filter", (lambda do |ctx, args|
      fn, coll = args
      coll.select {|i| fn[ctx, [i]] }
    end)

    define "distinct", ->(_ctx, args) { (args[0] || []).uniq }

    define "remove", (lambda do |ctx, args|
      fn, coll = args
      new_coll = coll.dup
      new_coll.delete_if {|i| fn[ctx, [i]] }
    end)

    define "def", (lambda do |ctx, args|
      ctx[args[0]] = ctx.evaluate args[1]
      "#{ctx['*ns*']}/#{args[0]}"
    end)

    define "merge", (lambda do |ctx, args|
      coll = ctx.evaluate args[0]
      args[1..].each do |arg|
        coll.merge! ctx.evaluate(arg)
      end
      coll
    end)

    define "assoc", (lambda do |ctx, args|
      coll = ctx.evaluate args[0]
      pairs = args[1..].map {|x| ctx.evaluate x }
      coll.merge(Hash[*pairs])
    end)

    define "first", (lambda do |_ctx, args|
      args.first.first
    end)

    define "rest", (lambda do |_ctx, args|
      args.first[1..]
    end)

    define "ns", (lambda do |ctx, args|
      self["def"][ctx, ["*ns*", ["quote", args[0]]]]
      if args[1] && args[1][0] == :require
        args[1][1..].each do |refer|
          ns = refer[1].to_sym
          binds = Hash[*refer[2..]]
          # @type var bindings: Hash[Symbol, untyped]
          bindings = {}
          bindings[binds[:as]] = [ns] if binds[:as]
          if binds[:refer]
            binds[:refer][1..].each do |ref|
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
      fn_name, arities = parse_fn(args)
      # @type var fn_proc: function
      fn_proc = lambda do |_ctx, fn_args|
        invoke_fn(ctx, fn_name, fn_proc, arities, fn_args)
      end
    end)

    define "defn", ->(ctx, args) { self["def"].call(ctx, [args[0], self["fn"].call(ctx, args[1..])]) }

    class << self
      def parse_fn(args)
        fn_name = args.first if args.first.is_a?(String)
        clauses = fn_name ? args.drop(1) : args
        raw_arities = vector_form?(clauses.first) ? [clauses] : clauses
        [fn_name, raw_arities.map {|clause| parse_arity(clause) }]
      end

      def vector_form?(form)
        form.is_a?(Array) && form.first == "vector"
      end

      def parse_arity(clause)
        params_form, *body = clause
        raise StandardError, "Parameter declaration should be a vector" unless vector_form?(params_form)

        fixed, rest_param = split_params(params_form.drop(1))
        [fixed, rest_param, body]
      end

      def split_params(raw_params)
        raise StandardError, "Destructuring is not supported in fn" unless raw_params.all?(String)
        return [raw_params, nil] unless raw_params.include?("&")

        amp_idx = raw_params.index("&") || 0
        raise StandardError, "Invalid parameter list" if raw_params.count("&") > 1 || amp_idx != raw_params.length - 2

        [raw_params.take(amp_idx), raw_params.last]
      end

      def match_arity(arities, arg_count)
        arities.find do |fixed, rest_param, _body|
          rest_param ? arg_count >= fixed.length : arg_count == fixed.length
        end
      end

      def invoke_fn(ctx, fn_name, fn_proc, arities, fn_args)
        arity = match_arity(arities, fn_args.length)
        raise StandardError, "Wrong number of args (#{fn_args.length}) passed to: #{fn_name || 'fn'}" unless arity

        fn_ctx = bind_fn_context(ctx, fn_name, fn_proc, arity, fn_args)
        arity[2].map {|form| fn_ctx.evaluate form }.last
      end

      def bind_fn_context(ctx, fn_name, fn_proc, arity, fn_args)
        fixed, rest_param, _body = arity
        fn_ctx = ctx.dup
        fn_ctx[fn_name] = fn_proc if fn_name
        fixed.each_with_index {|k, idx| fn_ctx[k] = fn_args[idx] }
        fn_ctx[rest_param] = fn_args[fixed.length..] || [] if rest_param
        fn_ctx
      end
    end
  end
end
