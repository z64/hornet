require "../spec_helper"

describe Hornet::Flipper do
  Hornet::Flipper.new("foo")
  Hornet::Flipper.new("bar")

  it "stores instanced features" do
    Hornet::Flipper.features.should eq ["foo", "bar"]
  end

  it "enables features per guild" do
    Hornet::Flipper.enable("foo", 1)
    result = Hornet::FlipperSettings.get("foo", 1)
    result.not_nil!.enabled.should be_true
  end

  it "disables features per guild" do
    Hornet::Flipper.disable("foo", 1)
    result = Hornet::FlipperSettings.get("foo", 1)
    result.not_nil!.enabled.should be_false
  end
end
