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
    SPECIAL = %w[ns fn defn def quote let for if do and or when when-not].freeze
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

    private

    def resolve(symbol)
      return LITERALS[symbol] if LITERALS.key?(symbol)

      n, ns = symbol.split("/").reverse
      i = lookup(symbol, n, ns)
      return i unless i.is_a?(Clojure::Alias)

      ns ? i.lookup[n] : i.lookup
    end

    def lookup(symbol, name, ns_name)
      return self[ns_name] if ns_name && key?(ns_name)
      return self[name] if name && key?(name)

      Clojure::Core[symbol] || raise("Can't resolve #{symbol}.")
    end

    def form_eval(form)
      return [] if form.empty?

      head, *expressions = form
      fn = case head
           when Array
             form_eval head
           when Symbol
             # dirty keyword IFn
             ->(_ctx, args) { args[0][head] }
           else
             resolve head
           end
      raise StandardError, "Function #{head} not defined" unless fn

      args = if head.is_a?(String) && SPECIAL.include?(head)
               expressions
             else
               expressions.map {|f| evaluate f }
             end
      fn.call self, args
    end
  end
end
