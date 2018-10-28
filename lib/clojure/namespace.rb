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

    def form_eval(form)
      fn = self[form.first] || Clojure::Core[form.first]
      fn.call self, form[1..-1].map { |f| evaluate f }
    end
  end
end