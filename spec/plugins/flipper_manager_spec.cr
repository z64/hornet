require "../spec_helper"

alias FlipCall = {Symbol, String, UInt64}
alias ListCall = Symbol

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

  it "responds with insufficient arguments" do
    command = MessageStub.new(1, "flipper")
    expected = "insufficient arguments (`action`, `name`, `id`)"
    plugin.handle(command, :ctx).should eq MessageStub.new(1, expected)
  end

  it "responds to unknown subcommand" do
    command = MessageStub.new(2, "flipper foo bar 1234")
    expected = "unknown flipper command: `foo`"
    plugin.handle(command, :ctx).should eq MessageStub.new(2, expected)
  end

  it "responds with features" do
    command = MessageStub.new(2, "flipper list")
    expected = <<-MESSAGE
      available features:
      ```cr
      #{plugin.features}
      ```
      MESSAGE
    plugin.handle(command, :ctx).should eq MessageStub.new(2, expected)
    plugin.last_call.should eq :list
  end

  it "enables features" do
    command = MessageStub.new(3, "flipper enable foo 123")
    expected = "enabled `foo` in `123`"
    plugin.handle(command, :ctx).should eq MessageStub.new(3, expected)
    plugin.last_call.should eq({:enable, "foo", 123_u64})
  end

  it "disables features" do
    command = MessageStub.new(4, "flipper disable foo 123")
    expected = "disabled `foo` in `123`"
    plugin.handle(command, :ctx).should eq MessageStub.new(4, expected)
    plugin.last_call.should eq({:disable, "foo", 123_u64})
  end

  it "doesn't process unknown features" do
    command = MessageStub.new(5, "flipper enable doesnt_exist 1234")
    expected = "unknown feature: `doesnt_exist`"
    plugin.handle(command, :ctx).should eq MessageStub.new(5, expected)
  end
end
