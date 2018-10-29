require "yaml"

RSpec.describe "Shared validation on Clojure" do
    it "valid data" do
      data = YAML.load_file('spec/integration/valid_team.yml')
      source = YAML.load_file('spec/integration/validation.clj')
      ast = Clojure::Reader.new(source).ast
      ns = Clojure::Namespace.new
      ast.each { |form| ns.evaluate form }
      expect(ns.evaluate ["validate", data]).to be true
    end
end