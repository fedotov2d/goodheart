module Clojure
  class Namespace < Hash
    # Clojure's ns | evaluation context | class

    def initialize
      self["+"] = ->(ctx, args) { args.reduce(:+)}
    end

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

    def form_eval(form)
      fn = self[form.first]
      fn.call self, form[1..-1]
    end
  end
end