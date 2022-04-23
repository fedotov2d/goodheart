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
      @namespaces[lib.name.downcase.gsub("::", ".").to_sym] = lib
    end

    def read(ns_name, source)
      ast = Clojure::Reader.new(source).ast
      ns = namespace ns_name.to_sym
      ast.map {|form| ns.evaluate form }.last
    end
  end
end
