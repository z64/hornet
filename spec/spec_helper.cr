require "spec"
require "../src/hornet"

alias ID = UInt64 | Discord::Snowflake

record MessageStub, channel_id : ID, content : String, embed : Discord::Embed? = nil
record MessageReactionStub, channel_id : ID, user_id : ID, message_id : ID, emoji : Discord::ReactionEmoji

module StubbedCachedRoutes
  record CachedChannel, guild_id : ID

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

  def on_message_reaction_add(&block : MessageReactionStub, Symbol ->)
    block
  end

  def on_message_reaction_add(_middleware, &block : MessageReactionStub, Symbol ->)
    block
  end

  def create_message(channel_id : ID, content : String, embed : Discord::Embed? = nil)
    MessageStub.new(channel_id, content, embed)
  end

  def edit_message(channel_id : ID, message_id : ID, content : String, embed : Discord::Embed? = nil)
    MessageStub.new(channel_id, content, embed)
  end

  def trigger_typing_indicator(channel_id : ID)
  end
end
