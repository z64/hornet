require "../spec_helper"

describe Hornet::Flipper do
  Hornet::Flipper.new("foo")
  Hornet::Flipper.new("bar")

  it "stores instanced features" do
    Hornet::Flipper.features.should eq ["foo", "bar"]
  end

  it "enables features per guild" do
    Hornet::Flipper.enable("foo", 1)
    Hornet::Flipper.store[{"foo", 1}].should eq true
    Hornet::Flipper.store[{"foo", 2}]?.should eq nil
  end

  it "disables features per guild" do
    Hornet::Flipper.disable("foo", 1)
    Hornet::Flipper.enable("foo", 3)
    Hornet::Flipper.store[{"foo", 1}].should eq false
    Hornet::Flipper.store[{"foo", 3}]?.should eq true
  end
end
