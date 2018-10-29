RSpec.describe Clojure::Runtime do
  it "load" do
    rt = described_class.new
    rt.load("spec/simple.clj")
    ns_simple = rt.namespace("simple")
    expect(ns_simple["answer"]).to eq 42
    expect(ns_simple.evaluate("answer")).to eq 42
    expect(ns_simple.evaluate(["answer+", 27])).to eq 69
  end
end