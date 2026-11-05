# frozen_string_literal: true

module Clojure
  class Namespace < Hash
    # Clojure's ns | evaluation context | class

    # rubocop:disable-next Lint/MissingSuper
    def initialize(runtime)
      @runtime = runtime
    end

    attr_reader :runtime

    # calls with postponed evaluation of expression
    SPECIAL = %w[
      ns fn defn defmacro def quote syntax-quote unquote unquote-splicing let for if do and or
    ].freeze
    LITERALS = { "true" => true, "false" => false, "nil" => nil }.freeze

    def evaluate(form)
      case form
      when Array
        form_eval form
      when String
        resolve form
      else
        form
      end
    end

    def resolve_macro(symbol)
      return nil unless symbol.is_a?(String) && !LITERALS.key?(symbol)

      n, ns_name = symbol.split("/").reverse
      target = unwrap_alias(find_entry(symbol, n, ns_name), n, ns_name)
      target if target.is_a?(Clojure::Macro)
    end

    private

    def resolve(symbol)
      return LITERALS[symbol] if LITERALS.key?(symbol)

      n, ns = symbol.split("/").reverse
      unwrap_alias(lookup(symbol, n, ns), n, ns)
    end

    def unwrap_alias(entry, name, ns_name)
      return entry unless entry.is_a?(Clojure::Alias)

      ns_name ? entry.lookup[name] : entry.lookup
    end

    def lookup(symbol, name, ns_name)
      return self[ns_name] if ns_name && key?(ns_name)
      return self[name] if name && key?(name)

      Clojure::Core[symbol] || raise("Can't resolve #{symbol}.")
    end

    def find_entry(symbol, name, ns_name)
      return self[ns_name] if ns_name && key?(ns_name)
      return self[name] if name && key?(name)

      Clojure::Core[symbol]
    end

    def form_eval(form)
      return [] if form.empty?

      head, *expressions = form
      fn = resolve_head(head)
      raise StandardError, "Function #{head} not defined" unless fn

      args = unevaluated_args?(head, fn) ? expressions : expressions.map {|f| evaluate f }
      fn.call self, args
    end

    def resolve_head(head)
      case head
      when Array
        form_eval head
      when Symbol
        # dirty keyword IFn
        ->(_ctx, args) { args[0][head] }
      else
        resolve head
      end
    end

    def unevaluated_args?(head, func)
      func.is_a?(Clojure::Macro) || (head.is_a?(String) && SPECIAL.include?(head))
    end
  end
end
