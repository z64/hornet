require "../spec_helper"

describe Hornet::FlipperSettings do
  it ".update" do
    Hornet::FlipperSettings.update("foo", 123, true)
    expected = Hornet::FlipperSettings.new(1, "foo", 123, true)
    if result = Hornet::FlipperSettings.get("foo", 123)
      expected.id = result.id
      result.should eq result
    else
      raise "FlipperSettings not found!"
    end
  end
end
