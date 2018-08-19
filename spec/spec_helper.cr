require "spec"
require "../src/hornet"

record MessageStub, channel_id : UInt64, content : String
record MessageWithEmbedStub, channel_id : UInt64, content : String, embed : Discord::Embed

module StubbedCachedRoutes
  record CachedChannel, guild_id : UInt64

  def get_channel(_client, channel_id)
    CachedChannel.new(guild_id: 1)
  end
end

class MockClient
  def on_message_create(&block : MessageStub ->)
    block
  end

  def on_message_create(_middleware, &block : MessageStub, Symbol ->)
    block
  end

  def create_message(channel_id : UInt64, content : String)
    MessageStub.new(channel_id, content)
  end

  def create_message(channel_id : UInt64, content : String, embed : Discord::Embed)
    MessageWithEmbedStub.new(channel_id, content, embed)
  end

  def trigger_typing_indicator(channel_id : UInt64)
  end
end
