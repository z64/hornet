require "../spec_helper"

private alias FlipCall = {Symbol, String, Discord::Snowflake}
private alias ListCall = Symbol

@[Discord::Plugin::Options(client_class: MockClient, middleware: true)]
class Hornet::FlipperManager
  include Discord::Plugin

  getter last_call : FlipCall? | ListCall? = nil

  def enable(name, id)
    @last_call = {:enable, name, id}
  end

  def disable(name, id)
    @last_call = {:disable, name, id}
  end

  def features
    @last_call = :list
    ["foo", "bar"]
  end
end

describe Hornet::FlipperManager do
  client = MockClient.new
  plugin = Hornet::FlipperManager.new
  plugin.register_on(client)

  it "lists features" do
    payload = MessageStub.new(2, 1, "flipper list")
    ctx = {Hornet::CommandParser::ParsedCommand => Hornet::CommandParser.parse(payload.content.lchop("flipper"))}
    expected = <<-MESSAGE
      available features:
      ```cr
      #{plugin.features}
      ```
      MESSAGE
    plugin.handle(payload, ctx).should eq MessageStub.new(2, 1, expected)
    plugin.last_call.should eq :list
  end

  it "enables features" do
    payload = MessageStub.new(3, 1, "flipper enable foo 123")
    ctx = {Hornet::CommandParser::ParsedCommand => Hornet::CommandParser.parse(payload.content.lchop("flipper"))}
    expected = "enabled `foo` in `123`"
    plugin.handle(payload, ctx).should eq MessageStub.new(3, 1, expected)
    plugin.last_call.should eq({:enable, "foo", 123_u64})
  end

  it "disables features" do
    payload = MessageStub.new(4, 1, "flipper disable foo 123")
    ctx = {Hornet::CommandParser::ParsedCommand => Hornet::CommandParser.parse(payload.content.lchop("flipper"))}
    expected = "disabled `foo` in `123`"
    plugin.handle(payload, ctx).should eq MessageStub.new(4, 1, expected)
    plugin.last_call.should eq({:disable, "foo", 123_u64})
  end

  it "doesn't process unknown features" do
    payload = MessageStub.new(5, 1, "flipper enable doesnt_exist 1234")
    ctx = {Hornet::CommandParser::ParsedCommand => Hornet::CommandParser.parse(payload.content.lchop("flipper"))}
    expected = "unknown feature: `doesnt_exist`"
    plugin.handle(payload, ctx).should eq MessageStub.new(5, 1, expected)
  end
end
