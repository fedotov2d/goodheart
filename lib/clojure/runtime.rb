module Clojure
  class Runtime
    def initialize
      @namespaces = {}
    end

    def namespace(name)
      @namespaces[name] ||= Clojure::Namespace.new(self)
    end

    def load(filename)
      ns = Clojure::Namespace.new(self)
      source = open(filename).read
      ast = Clojure::Reader.new(source).ast
      ast.each { |form| ns.evaluate form }
      ns_name = ns["*ns*"]
      @namespaces[ns_name] = namespace(ns_name).merge(ns)
    end

    def read(ns_name, source)
      ast = Clojure::Reader.new(source).ast
      ns = namespace ns_name
      ast.map { |form| ns.evaluate form }.last
    end
  end
end
