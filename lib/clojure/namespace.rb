module Clojure
  class Namespace < Hash
    # Clojure's ns | evaluation context | class

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
      fn.call self, expressions.map { |f| evaluate f }
    end
  end
end