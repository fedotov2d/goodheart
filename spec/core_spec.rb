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
    expect(described_class["quote"][{}, %w[good heart]]).to eq %w[good heart]
  end

  it "str" do
    expect(described_class["str"][{}, %w[good heart]]).to eq "goodheart"
  end
end