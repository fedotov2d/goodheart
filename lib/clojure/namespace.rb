module Clojure
  class Namespace < Hash
    # Clojure's ns | evaluation context | class

    def initialize(runtime)
      @runtime = runtime
    end

    attr_reader :runtime

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
      head, *expressions = form
      fn = case head
           when Array
             form_eval head
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
