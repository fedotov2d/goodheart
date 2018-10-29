module Clojure
  class Namespace < Hash
    # Clojure's ns | evaluation context | class

    # calls woth postponed evaluation of expression
    SPECIAL = %w[ns fn defn def quote].freeze

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
      self[symbol] || Clojure::Core[symbol]
    end

    def form_eval(form)
      name, *expressions = form
      fn = resolve name
      raise Exception, "Function #{name} not defined" unless fn
      args = if SPECIAL.include?(name)
        expressions
      else
        expressions.map { |f| evaluate f }
      end
      fn.call self, args
    end
  end
end