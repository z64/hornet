require "../spec_helper"

@[Discord::Plugin::Options(client_class: MockClient, middleware: true)]
class Hornet::Shibe
  include Discord::Plugin

  STUB_URLS = [
    ["foo", "bar"],
    ["fizz", "buzz"],
  ]

  def fetch_urls
    @urls = STUB_URLS.shift
  end
end

describe Hornet::Shibe do
  client = MockClient.new
  plugin = Hornet::Shibe.new
  plugin.register_on(client)

  it "responds with the next URL" do
    {"foo", "bar", "fizz", "buzz"}.each do |expected|
      response = plugin.handle(MessageStub.new(1, "message"), :ctx)
      response.embed.try &.image.try &.url.should eq expected
    end

    expect_raises(Exception) do
      plugin.handle(MessageStub.new(1, "message"), :ctx)
    end
  end
end
