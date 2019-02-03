RSpec.describe "Simple application with few namespaces" do
  let!(:rt) do
    rt = Clojure::Runtime.new
    rt.load('spec/integration/shared.clj')
    rt.load('spec/integration/app.clj')
    rt
  end

  context "loads" do
    it "namespaces" do
    end
  end
end
