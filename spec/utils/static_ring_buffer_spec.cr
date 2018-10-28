require "./spec_helper"

describe StaticRingBuffer do
  it "acts as a fixed size ring buffer" do
    buffer = StaticRingBuffer(Int32, 3).new
    buffer.push(1)
    buffer.push(2)
    buffer.push(3)
    buffer.push(4)
    buffer.to_a.should eq [2, 3, 4]
  end

  it "serializes to JSON" do
    arr = [1, 2, 3]
    buffer = StaticRingBuffer(Int32, 3).new
    arr.each { |i| buffer.push(i) }
    buffer.to_json.should eq arr.to_json
  end
end
