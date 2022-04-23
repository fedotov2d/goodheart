# frozen_string_literal: true

RSpec.describe "Simple application with few namespaces" do
  let!(:rt) do
    rt = Clojure::Runtime.new
    source1 = open("spec/integration/shared.clj").read
    rt.read("shared", source1)
    source2 = open("spec/integration/app.clj").read
    rt.read("app", source2)
    rt
  end

  context "loads" do
    it "namespaces" do
    end
  end
end
