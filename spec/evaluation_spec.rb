RSpec.describe Clojure::Namespace do
  it "evaluate simple form" do
    ns = described_class.new
    form = ["+", 1, 2]
    expect(ns.evaluate form).to eq(3)
  end
end