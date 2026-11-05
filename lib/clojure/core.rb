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
    define "list", ->(_ctx, args) { [*args] }
    define "cons", ->(_ctx, args) { [args[0], *(args[1] || [])] }
    define "concat", ->(_ctx, args) { args.compact.flatten(1) }
    define "hash-map", ->(_ctx, args) { Hash[*args] }

    define "str", ->(_ctx, args) { args.join }
    define "quote", ->(_ctx, args) { args.first }
    define "syntax-quote", ->(ctx, args) { syntax_quote(ctx, args.first, {}) }
    define "unquote", ->(_ctx, _args) { raise StandardError, "Unquote outside syntax-quote" }
    define "unquote-splicing", ->(_ctx, _args) { raise StandardError, "Unquote-splicing outside syntax-quote" }
    define "gensym", ->(_ctx, args) { next_gensym(args.first || "G__") }

    define "not", ->(_ctx, args) { !args.first }
    define "nil?", ->(_ctx, args) { args.first.nil? }
    define "empty?", ->(_ctx, args) { (args.first || []).empty? }
    define "seq", ->(_ctx, args) { args.first.nil? || args.first.empty? ? nil : args.first }

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

    define_macro "when", (lambda do |_ctx, args|
      clause, *body = args
      ["if", clause, ["do", *body], nil]
    end)

    define_macro "when-not", (lambda do |_ctx, args|
      clause, *body = args
      ["if", clause, nil, ["do", *body]]
    end)

    define_macro "if-not", (lambda do |_ctx, args|
      clause, then_expr, else_expr = args
      ["if", clause, else_expr, then_expr]
    end)

    define_macro "cond", (lambda do |_ctx, args|
      return nil if args.empty?
      raise StandardError, "cond requires an even number of forms" if args.length.odd?

      clause, then_expr, *more = args
      ["if", clause, then_expr, ["cond", *more]]
    end)

    define_macro "->", (lambda do |_ctx, args|
      x, *forms = args
      forms.inject(x) {|acc, form| thread_first_step(acc, form) }
    end)

    define_macro "->>", (lambda do |_ctx, args|
      x, *forms = args
      forms.inject(x) {|acc, form| thread_last_step(acc, form) }
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

    define "second", ->(_ctx, args) { (args.first || [])[1] }

    define "last", ->(_ctx, args) { (args.first || []).last }

    define "rest", (lambda do |_ctx, args|
      args.first[1..]
    end)

    define "apply", (lambda do |ctx, args|
      fn, *leading, tail = args
      fn.call(ctx, [*leading, *(tail || [])])
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

    define "defmacro", (lambda do |ctx, args|
      name, *clauses = args
      # @type var fn_proc: function
      fn_proc = self["fn"].call(ctx, [name, *clauses])
      ctx[name] = Clojure::Macro.new(fn_proc)
      "#{ctx['*ns*']}/#{name}"
    end)

    define "macroexpand-1", ->(ctx, args) { macroexpand_once(ctx, args.first) }

    define "macroexpand", ->(ctx, args) { macroexpand_all(ctx, args.first) }

    class << self
      def next_gensym(prefix="G__")
        @gensym_counter = (@gensym_counter || 0) + 1
        "#{prefix}#{@gensym_counter}"
      end

      def syntax_quote(ctx, form, gensyms)
        case form
        when String
          syntax_quote_symbol(form, gensyms)
        when Array
          syntax_quote_array(ctx, form, gensyms)
        else
          form
        end
      end

      def syntax_quote_symbol(symbol, gensyms)
        return symbol unless symbol.end_with?("#") && symbol.length > 1

        gensyms[symbol] ||= next_gensym("#{symbol.chop}__")
      end

      def syntax_quote_array(ctx, form, gensyms)
        return ctx.evaluate(form[1]) if form.first == "unquote"
        raise StandardError, "Unquote-splicing not in list" if form.first == "unquote-splicing"
        return form if form.first == "syntax-quote"

        syntax_quote_list(ctx, form, gensyms)
      end

      def syntax_quote_list(ctx, list, gensyms)
        # @type var result: Array[untyped]
        result = []
        list.each do |elem|
          if elem.is_a?(Array) && elem.first == "unquote-splicing"
            spliced = ctx.evaluate(elem[1])
            result.concat(spliced) if spliced
          else
            result << syntax_quote(ctx, elem, gensyms)
          end
        end
        result
      end

      def macroexpand_once(ctx, form)
        return form unless form.is_a?(Array) && !form.empty?

        macro = ctx.resolve_macro(form.first)
        macro ? macro.expand(ctx, form.drop(1)) : form
      end

      def macroexpand_all(ctx, form)
        current = form
        loop do
          expanded = macroexpand_once(ctx, current)
          return expanded if expanded.equal?(current) || expanded == current

          current = expanded
        end
      end

      def thread_first_step(acc, form)
        form.is_a?(Array) ? [form.first, acc, *form.drop(1)] : [form, acc]
      end

      def thread_last_step(acc, form)
        form.is_a?(Array) ? [*form, acc] : [form, acc]
      end

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
