require "yaml"

RSpec.describe "Shared validation on Clojure" do
    let(:ns) do
      rt = Clojure::Runtime.new
      rt.load('spec/integration/validation.clj')
      rt.namespace "validation"
    end

    let(:valid_data) { YAML.load_file('spec/integration/valid_team.yml') }
    let(:invalid_data) { YAML.load_file('spec/integration/invalid_team.yml') }

    context "simple" do
      it "valid data" do
        expect(ns.evaluate ["simple-validate", valid_data]).to be true
      end

      it "invalid data" do
        expect(ns.evaluate ["simple-validate", invalid_data]).to be false
      end
    end
end