# frozen_string_literal: true

class LibA
  extend Clojure::Library
  define 'foo', ->(_, args) { args[0] + 2 }
end

class LibB
  extend Clojure::Library
  define 'bar', ->(_, args) { args[0] * 2 }
end

RSpec.describe Clojure::Library do
  it 'foo of A' do
    expect(LibA['foo'][{}, [4]]).to eq 6
  end

  it 'bar of B' do
    expect(LibB['bar'][{}, [4]]).to eq 8
  end

  it 'bar of B not polute A' do
    expect(LibA['bar']).to be nil
  end

  it 'foo of A not polute B' do
    expect(LibB['foo']).to be nil
  end
end
