# frozen_string_literal: true

RSpec.describe Clojure::Namespace do
  it "evaluate simple form" do
    ns = described_class.new({})
    form = ["+", 1, 2]
    expect(ns.evaluate(form)).to eq(3)
  end

  it "evaluate nested form" do
    ns = described_class.new({})
    a = ns.evaluate ["+", ["+", 1, 2], ["+", 3, 4, 5], 6]
    b = ns.evaluate ["+", 1, 2, 3, 4, 5, 6]
    expect(a).to eq(b)
  end

  it "resolve boolean and nil literals and bindings" do
    ns = described_class.new({})
    expect(ns.evaluate(["let", %w[vector a false b nil], %w[vector a b true]])).to eq([false, nil, true])
  end

  it "short-circuit control flow special forms" do
    ns = described_class.new({})
    expect(ns.evaluate(["if", "true", 10, ["boom"]])).to eq(10)
    expect(ns.evaluate(["and", 1, "false", ["boom"]])).to be(false)
    expect(ns.evaluate(["or", "false", 42, ["boom"]])).to eq(42)
    expect(ns.evaluate(["when", "false", ["boom"]])).to be_nil
  end
end
