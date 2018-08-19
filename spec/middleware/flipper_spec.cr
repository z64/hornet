require "../spec_helper"

class Hornet::Flipper
  include StubbedCachedRoutes
end

describe Hornet::Flipper do
  foo_flipper = Hornet::Flipper.new("foo")
  bar_flipper = Hornet::Flipper.new("bar")

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

  it "#call on enabled guild" do
    Hornet::Flipper.enable("foo", 1)
    Hornet::Flipper.disable("bar", 1)
    ctx = {Discord::Client => :client}

    foo_called = false
    foo_flipper.call(MessageStub.new(1, "content"), ctx) do
      foo_called = true
    end
    foo_called.should be_true

    bar_called = false
    bar_flipper.call(MessageStub.new(1, "content"), ctx) do
      bar_called = true
    end
    bar_called.should be_false
  end
end
