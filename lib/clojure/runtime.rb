module Clojure
  class Runtime
    def initialize
      @namespaces = {}
    end

    def namespace(name)
      @namespaces[name] || @namespaces[name] = Clojure::Namespace.new
    end

    def load(filename)
      ns = Clojure::Namespace.new
      source = open(filename).read
      ast = Clojure::Reader.new(source).ast
      ast.each { |form| ns.evaluate form }
      ns_name = ns["*ns*"]
      @namespaces[ns_name] = namespace(ns_name).merge(ns)
    end
  end
end