RSpec.describe Clojure::Core do
  let(:ns) { Clojure::Namespace.new }

  it "+" do
    expect(described_class["+"][ns, [1, 2, 3]]).to eq 6
  end

  it "-" do
    expect(described_class["-"][ns, [9, 2, 1]]).to eq 6
  end

  it "*" do
    expect(described_class["*"][ns, [3, 2, 1]]).to eq 6
  end

  it "/" do
    expect(described_class["/"][ns, [36, 3, 2]]).to eq 6
  end

  it "=" do
    expect(described_class["="][ns, [3, 3, 3]]).to be true
    expect(described_class["="][ns, [3, 3, 2]]).to be false
  end

  it "<" do
    expect(described_class["<"][ns, [1, 2, 3]]).to be true
    expect(described_class["<"][ns, [3, 3, 2]]).to be false
  end

  it ">" do
    expect(described_class["<"][ns, [1, 2, 3]]).to be true
    expect(described_class["<"][ns, [3, 3, 2]]).to be false
  end

  it "vector" do
    expect(described_class["vector"][ns, [1, 2, 3]]).to eq([1, 2, 3])
  end

  it "hash-map" do
    expect(described_class["hash-map"][ns, [:a, 2, :b, 4]]).to eq({a: 2, b: 4})
  end

  it "quote" do
    expect(described_class["quote"][ns, ["good heart"]]).to eq "good heart"
  end

  it "str" do
    expect(described_class["str"][ns, %w[good heart]]).to eq "goodheart"
    expect(described_class["str"][ns, ["good heart"]]).to eq "good heart"
  end

  it "not" do
    expect(described_class["not"][ns, true]).to be false
    expect(described_class["not"][ns, false]).to be true
  end

  it "nil?" do
    expect(described_class["nil?"][ns, [1]]).to be false
    expect(described_class["nil?"][ns, [nil]]).to be true
  end

  it "and" do
    expect(described_class["and"][ns, [1, 2, 3]]).to be true
    expect(described_class["and"][ns, [1, 2, nil]]).to be false
  end

  it "or" do
    expect(described_class["or"][ns, [1, 2, 3]]).to be 1
    expect(described_class["or"][ns, [nil, 2, 3]]).to be 2
    expect(described_class["or"][ns, [nil, nil, nil]]).to be nil
  end

  it "if" do
    expect(described_class["if"][ns, [true, 1, 2]]).to be 1
    expect(described_class["if"][ns, [nil, 1, 2]]).to be 2
  end

  it "when" do
    expect(described_class["when"][ns, [true, 1]]).to be 1
    expect(described_class["when"][ns, [nil, 1]]).to be nil
  end

  it "when-not" do
    expect(described_class["when-not"][ns, [true, 1]]).to be nil
    expect(described_class["when-not"][ns, [nil, 1]]).to be 1
  end

  it "map" do
    ns["func"] = ->(ctx, args) { args[0] * 2 }
    expect(described_class["map"][ns, [ns.evaluate("func"), [1, 2, 3]]]).to eq [2, 4, 6]
  end

  it "filter" do
    ns["func"] = ->(_ctx, args) { args[0].even? }
    expect(described_class["filter"][ns, [ns.evaluate("func"), [1, 2, 3, 4]]]).to eq [2, 4]
  end

  it "remove" do
    expect(described_class["remove"][ns, [ns.evaluate("nil?"), [2, nil, 6]]]).to eq [2, 6]
    expect(described_class["remove"][ns, [ns.evaluate("nil?"), [nil, nil]]]).to be_empty
  end

  it "get" do
    expect(described_class["get"][ns, [[1, 2, 3], 2]]).to eq 3
    expect(described_class["get"][ns, [{a: 1, b: 2}, :b]]).to eq 2
  end

  it "count" do
    expect(described_class["count"][ns, [%w[good heart]]]).to eq 2
    expect(described_class["count"][ns, [[]]]).to eq 0
    expect(described_class["count"][ns, ["four"]]).to eq 4
    expect(described_class["count"][ns, [""]]).to eq 0
  end

  it "distinct" do
    expect(described_class["distinct"][ns, [%w[good heart good]]]).to eq %w[good heart]
  end

  it "fn" do
    fn = described_class["fn"][ns, [%w[vector a b], %w[+ a b]]]
    expect(fn.call(ns, [1, 2])).to eq 3
  end

  it "def" do
    described_class["def"][ns, ["a", 1]]
    expect(ns["a"]).to eq 1
  end

  it "defn" do
    described_class["defn"][ns, ["sum", %w[vector a b], %w[+ a b]]]
    expect(ns["sum"].call(ns, [1, 2])).to eq 3
  end

  it "ns" do
    described_class["ns"][ns, ["main"]]
    expect(ns["*ns*"]).to eq "main"
  end
end