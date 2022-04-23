# frozen_string_literal: true

require "yaml"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "Shared validation on Clojure" do
  let(:ns) do
    rt = Clojure::Runtime.new
    source = open("spec/integration/validation.clj").read
    rt.read("validation", source)
    rt.namespace "validation"
  end

  let(:valid_data) { YAML.load_file("spec/integration/valid_team.yml") }
  let(:invalid_data) { YAML.load_file("spec/integration/invalid_team.yml") }

  context "when simple" do
    it "valid data" do
      expect(ns.evaluate(["simple-validate", valid_data])).to be true
    end

    it "invalid data" do
      expect(ns.evaluate(["simple-validate", invalid_data])).to be false
    end
  end

  context "when advanced" do
    it "valid data" do
      errors = ns.evaluate ["advanced-validate", valid_data]
      expect(errors).to be_empty
    end

    it "invalid data" do
      errors = ns.evaluate ["advanced-validate", invalid_data]
      expect(errors).to include "Team name should be present"
      expect(errors).to include "Team should be greater than three members"
    end
  end
end
# rubocop:enable RSpec/DescribeClass
