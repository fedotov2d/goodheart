# frozen_string_literal: true

RSpec.describe Clojure::Namespace do
  it 'evaluate simple form' do
    ns = described_class.new({})
    form = ['+', 1, 2]
    expect(ns.evaluate(form)).to eq(3)
  end

  it 'evaluate nested form' do
    ns = described_class.new({})
    a = ns.evaluate ['+', ['+', 1, 2], ['+', 3, 4, 5], 6]
    b = ns.evaluate ['+', 1, 2, 3, 4, 5, 6]
    expect(a).to eq(b)
  end
end
