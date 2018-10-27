RSpec.describe Clojure::Reader do
  it "read lists correct" do
    r = described_class.new "( (),(( ) ,(),))"
    expect(r.ast).to eq [[[], [[], []]]]
  end

  it "raise exception on unbalanced list" do
    expect { described_class.new "(()," }.to raise_error(Exception, "Unbalanced ()")
  end
end
