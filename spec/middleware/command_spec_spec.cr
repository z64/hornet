require "../spec_helper"

private class ContextWithClient
  def initialize(@client : MockClient)
  end

  def put(_class)
  end

  def [](_class)
    @client
  end
end

describe Hornet::CommandSpec do
  it "yields on matching command" do
    client = MockClient.new
    ctx = ContextWithClient.new(client)
    spec = Hornet::CommandSpec.new("foo", "usage")
    {"h>foo", "h>    foo"}.each do |content|
      payload = MessageStub.new(1, 1, content)
      called = false
      spec.call(payload, ctx) { called = true }
      called.should be_true
    end
  end

  it "ignores mismatching command" do
    client = MockClient.new
    ctx = ContextWithClient.new(client)
    spec = Hornet::CommandSpec.new("foo", "usage")
    {"foo", "h>    bar", ""}.each do |content|
      payload = MessageStub.new(1, 1, content)
      called = false
      spec.call(payload, ctx) { called = true }
      called.should be_false
    end
  end

  it "responds to too few arguments" do
    client = MockClient.new
    ctx = ContextWithClient.new(client)
    spec = Hornet::CommandSpec.new("foo", "usage", 2)
    payload = MessageStub.new(1, 1, "h>foo 1")

    called = false
    response = spec.call(payload, ctx) { called = true }
    called.should be_false
    response.should eq MessageStub.new(1, 1, <<-MESSAGE)
    `<error>` too few arguments (1 given, minimum: 2)
    `<usage>` usage
    MESSAGE
  end

  it "responds to too many arguments" do
    client = MockClient.new
    ctx = ContextWithClient.new(client)
    spec = Hornet::CommandSpec.new("foo", "usage", nil, 2)
    payload = MessageStub.new(1, 1, "h>foo 1 2 3")

    called = false
    response = spec.call(payload, ctx) { called = true }
    called.should be_false
    response.should eq MessageStub.new(1, 1, <<-MESSAGE)
    `<error>` too many arguments (3 given, maximum: 2)
    `<usage>` usage
    MESSAGE
  end

  it "responds to Argument or ParsedCommand errors" do
    client = MockClient.new
    ctx = ContextWithClient.new(client)
    spec = Hornet::CommandSpec.new("foo", "usage")
    payload = MessageStub.new(1, 1, "h>foo")

    response = spec.call(payload, ctx) do
      raise Hornet::CommandParser::Argument::Error.new("reason")
    end
    response.should eq MessageStub.new(1, 1, <<-MESSAGE)
    `<error>` reason
    `<usage>` usage
    MESSAGE

    response = spec.call(payload, ctx) do
      raise Hornet::CommandParser::ParsedCommand::Error.new("reason")
    end
    response.should eq MessageStub.new(1, 1, <<-MESSAGE)
    `<error>` reason
    `<usage>` usage
    MESSAGE
  end
end
