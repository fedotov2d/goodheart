module Clojure
  class Namespace < Hash
    # Clojure's ns | evaluation context | class

    def initialize(runtime)
      @runtime = runtime
    end

    attr_reader :runtime

    # calls with postponed evaluation of expression
    SPECIAL = %w[ns fn defn def quote let for].freeze

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
      n, ns = symbol.split('/').reverse
      i = self[ns] || self[n] || Clojure::Core[symbol] || raise("Can't resolve #{symbol}.")
      case i
      when Clojure::Alias
        if ns
          i.lookup()[n]
        else
          i.lookup()
        end
      else
        i
      end
    end

    def form_eval(form)
      head, *expressions = form
      fn = case head
           when Array
             form_eval head
           when Symbol
             # dirty keyword IFn
             -> (_ctx, args) { args[0][head] }
           else
             resolve head
           end
      raise Exception, "Function #{head} not defined" unless fn
      args = if head.is_a?(String) && SPECIAL.include?(head)
               expressions
             else
               expressions.map { |f| evaluate f }
             end
      fn.call self, args
    end
  end
end
