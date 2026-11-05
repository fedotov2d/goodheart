# frozen_string_literal: true

RSpec.describe Clojure::Macro do
  let(:rt) { Clojure::Runtime.new }

  before { rt.read("user", "(ns user)") }

  it "defines and evaluates macros built with list construction" do
    rt.read("user", "(defmacro unless [pred then-form else-form] (list 'if pred else-form then-form))")
    expect(rt.read("user", "(unless false (+ 1 2) (boom))")).to eq(3)
    expect(rt.read("user", "(unless true (boom) (+ 4 5))")).to eq(9)
  end

  it "defines and evaluates macros using syntax-quote, unquote, and unquote-splicing" do
    rt.read("user", "(defmacro unless-do [pred & body] `(if ~pred nil (do ~@body)))")
    expect(rt.read("user", "(unless-do false (+ 1 1) (+ 2 3))")).to eq(5)
    expect(rt.read("user", "(unless-do true (boom))")).to be_nil
  end

  it "supports multi-arity macros" do
    rt.read(
      "user",
      "(defmacro add-or-inc ([x] `(+ ~x 1)) ([x y] `(+ ~x ~y)))"
    )
    expect(rt.read("user", "(add-or-inc 10)")).to eq(11)
    expect(rt.read("user", "(add-or-inc 10 20)")).to eq(30)
  end

  it "expands one step with macroexpand-1 and all steps with macroexpand" do
    rt.read("user", "(defmacro unless [pred & body] `(when-not ~pred ~@body))")
    expect(rt.read("user", "(macroexpand-1 '(unless true 1 2))")).to eq(["when-not", "true", 1, 2])
    expect(rt.read("user", "(macroexpand '(unless true 1 2))")).to eq(["if", "true", nil, ["do", 1, 2]])
    expect(rt.read("user", "(macroexpand-1 '(+ 1 2))")).to eq(["+", 1, 2])
    expect(rt.read("user", "(macroexpand-1 '(unknown-fn 1))")).to eq(["unknown-fn", 1])
  end

  it "preserves hygiene with auto-gensym across nested expansions" do
    rt.read("user", "(defmacro twice [expr] `(let [v# ~expr] (+ v# v#)))")
    expect(rt.read("user", "(let [v 100] (twice (+ v 1)))")).to eq(202)
    expect(rt.read("user", "(twice (twice 3))")).to eq(12)
  end

  it "evaluates expanded forms in the caller lexical scope and across namespaces" do
    rt.read("macros", "(ns macros) (defmacro double-var [x] `(+ ~x ~x))")
    rt.read("app", "(ns app (:require [macros :as m :refer [double-var]]))")
    expect(rt.read("app", "(let [local 7] (double-var local))")).to eq(14)
    expect(rt.read("app", "(let [local 9] (m/double-var local))")).to eq(18)
  end

  it "evaluates core threading and conditional macros end-to-end" do
    expect(rt.read("user", "(-> 5 (+ 3) (* 2))")).to eq(16)
    expect(rt.read("user", "(->> [1 2 3] (map (fn [x] (* x 2))) rest first)")).to eq(4)
    expect(rt.read("user", "(cond (= 1 2) :no (= 2 2) :yes :else :fallback)")).to eq(:yes)
    expect(rt.read("user", "(if-not (= 1 2) :different :same)")).to eq(:different)
  end

  it "raises on unquote or unquote-splicing misused outside syntax-quote lists" do
    expect { rt.read("user", "~x") }.to raise_error(StandardError, "Unquote outside syntax-quote")
    expect { rt.read("user", "~@x") }.to raise_error(StandardError, "Unquote-splicing outside syntax-quote")
    expect { rt.read("user", "`~@x") }.to raise_error(StandardError, "Unquote-splicing not in list")
  end
end
