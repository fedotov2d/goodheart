RSpec.describe Clojure::Reader do
  it "read lists correct" do
    r = described_class.new "( (),(( ) ,(),))"
    expect(r.ast).to eq [[[], [[], []]]]
  end

  it "raise exception on unbalanced list" do
    expect { described_class.new "(()," }.to raise_error(Exception, "Unbalanced ()")
  end

  it "read vector correct" do
    r = described_class.new "[1 2,3]"
    expect(r.ast).to eq [["vector", 1, 2, 3]]
  end

  it "raise exception on unbalanced vector" do
    expect { described_class.new "[123 [" }.to raise_error(Exception, "Unbalanced []")
  end

  it "read hash map correct" do
    r = described_class.new "{1 2 3 4}"
    expect(r.ast).to eq [["hash-map", 1, 2, 3, 4]]
  end

  it "raise exception on unbalanced hash map" do
    expect { described_class.new "{1" }.to raise_error(Exception, "Unbalanced {}")
  end

  it "read symbol correct" do
    r = described_class.new " vector "
    expect(r.ast).to eq ["vector"]
  end

  it "read keyword correct" do
    r = described_class.new " :name "
    expect(r.ast).to eq [:name]
  end
end
