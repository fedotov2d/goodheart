# frozen_string_literal: true

module Clojure
  class Runtime
    def initialize
      @namespaces = {}
    end

    attr_reader :namespaces

    def namespace(name)
      @namespaces[name.to_sym] ||= Clojure::Namespace.new(self)
    end

    def include(lib)
      @namespaces[lib.name.downcase.gsub('::', '.').to_sym] = lib
    end

    def load(filename)
      ns = Clojure::Namespace.new(self)
      source = open(filename).read
      ast = Clojure::Reader.new(source).ast
      ast.each { |form| ns.evaluate form }
      ns_name = ns['*ns*']
      @namespaces[ns_name.to_sym] = namespace(ns_name).merge(ns)
    end

    def read(ns_name, source)
      ast = Clojure::Reader.new(source).ast
      ns = namespace ns_name.to_sym
      ast.map { |form| ns.evaluate form }.last
    end
  end
end
