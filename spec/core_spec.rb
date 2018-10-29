RSpec.describe Clojure::Core do
  it "+" do
    expect(described_class["+"][{}, [1, 2, 3]]).to eq 6
  end

  it "-" do
    expect(described_class["-"][{}, [9, 2, 1]]).to eq 6
  end

  it "*" do
    expect(described_class["*"][{}, [3, 2, 1]]).to eq 6
  end

  it "/" do
    expect(described_class["/"][{}, [36, 3, 2]]).to eq 6
  end

  it "=" do
    expect(described_class["="][{}, [3, 3, 3]]).to be true
    expect(described_class["="][{}, [3, 3, 2]]).to be false
  end

  it "<" do
    expect(described_class["<"][{}, [1, 2, 3]]).to be true
    expect(described_class["<"][{}, [3, 3, 2]]).to be false
  end

  it ">" do
    expect(described_class["<"][{}, [1, 2, 3]]).to be true
    expect(described_class["<"][{}, [3, 3, 2]]).to be false
  end

  it "vector" do
    expect(described_class["vector"][{}, [1, 2, 3]]).to eq([1, 2, 3])
  end

  it "hash-map" do
    expect(described_class["hash-map"][{}, [:a, 2, :b, 4]]).to eq({a: 2, b: 4})
  end

  it "quote" do
    expect(described_class["quote"][{}, ["good heart"]]).to eq "good heart"
  end

  it "str" do
    expect(described_class["str"][{}, %w[good heart]]).to eq "goodheart"
    expect(described_class["str"][{}, ["good heart"]]).to eq "good heart"
  end

  it "not" do
    expect(described_class["not"][{}, true]).to be false
    expect(described_class["not"][{}, false]).to be true
  end

  it "get" do
    expect(described_class["get"][{}, [[1, 2, 3], 2]]).to eq 3
    expect(described_class["get"][{}, [{a: 1, b: 2}, :b]]).to eq 2
  end

  it "count" do
    expect(described_class["count"][{}, [%w[good heart]]]).to eq 2
    expect(described_class["count"][{}, [[]]]).to eq 0
    expect(described_class["count"][{}, ["four"]]).to eq 4
    expect(described_class["count"][{}, [""]]).to eq 0
  end

  it "fn" do
    ns = Clojure::Namespace.new
    fn = described_class["fn"][ns, [%w[vector a b], %w[+ a b]]]
    expect(fn.call({}, [1, 2])).to eq 3
  end

  it "def" do
    ns = Clojure::Namespace.new
    described_class["def"][ns, %w[a b]]
    expect(ns["a"]).to eq "b"
  end

  it "defn" do
    ns = Clojure::Namespace.new
    described_class["defn"][ns, ["sum", %w[vector a b], %w[+ a b]]]
    expect(ns["sum"].call({}, [1, 2])).to eq 3
  end
end