require "./spec_helper"

describe Hornet do
  describe ".get_plugin" do
    it "fetches global plugin instances" do
      Hornet.get_plugin(Hornet::FlipperManager).should be_a Hornet::FlipperManager
    end
  end
end
