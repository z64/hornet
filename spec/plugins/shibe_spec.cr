require "../spec_helper"

@[Discord::Plugin::Options(client_class: MockClient, middleware: true)]
class Hornet::Shibe
  include Discord::Plugin

  STUB_URLS = [
    ["foo", "bar"],
    ["fizz", "buzz"],
  ]

  def fetch_urls(kind)
    @urls[kind] = STUB_URLS.shift
  end
end

describe Hornet::Shibe do
  client = MockClient.new
  plugin = Hornet::Shibe.new
  plugin.register_on(client)

  it "responds with the next URL" do
    {"foo", "bar", "fizz", "buzz"}.each do |expected|
      response = plugin.shibe(MessageStub.new(1, 2, "message"), Discord::Context.new)
      response.embed.image.try &.url.should eq expected
    end

    expect_raises(Exception) do
      plugin.shibe(MessageStub.new(1, 2, "message"), Discord::Context.new)
    end
  end
end
