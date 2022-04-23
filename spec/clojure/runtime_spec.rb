# frozen_string_literal: true

RSpec.describe Clojure::Runtime do
  let(:rt) { described_class.new }

  before { rt.read "user", "(ns user)" }

  it "load" do
    source = open("spec/simple.clj").read
    rt.read("simple", source)
    ns_simple = rt.namespace(:simple)
    expect(ns_simple["answer"]).to eq 42
    expect(ns_simple.evaluate("answer")).to eq 42
    expect(ns_simple.evaluate(["answer+", 27])).to eq 69
  end

  it "read" do
    expect(rt.read("user", "(+ 1 2 3)")).to eq 6
    expect(rt.read("user", "(def a 3)")).to eq "user/a"
    expect(rt.read("user", "(def b 6)")).to eq "user/b"
    expect(rt.read("user", "(+ a b)")).to eq 9
  end
end
