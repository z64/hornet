require "spec"
require "../src/hornet"

Micrate::DB.connection_url = ENV["HORNET_DB_URL"]
Micrate.up(Hornet::DB, "src/database/migrations")

record MessageAuthor, id : Discord::Snowflake, username : String do
  def self.new(id, username)
    id = Discord::Snowflake.new(id.to_u64)
    new(id, username)
  end
end

record MessageStub, channel_id : Discord::Snowflake, guild_id : Discord::Snowflake, content : String, author : MessageAuthor do
  def self.new(channel_id, guild_id, content)
    channel_id = Discord::Snowflake.new(channel_id.to_u64)
    guild_id = Discord::Snowflake.new(guild_id.to_u64)
    author = MessageAuthor.new(1, "z64")
    new(channel_id, guild_id, content, author)
  end

  def self.new(channel_id, guild_id, content, author)
    channel_id = Discord::Snowflake.new(channel_id.to_u64)
    guild_id = Discord::Snowflake.new(guild_id.to_u64)
    new(channel_id, guild_id, content, author)
  end
end

record MessageWithEmbedStub, channel_id : Discord::Snowflake, guild_id : Discord::Snowflake, content : String, author : MessageAuthor, embed : Discord::Embed do
  def self.new(channel_id, guild_id, content, embed)
    channel_id = Discord::Snowflake.new(channel_id.to_u64)
    guild_id = Discord::Snowflake.new(guild_id.to_u64)
    author = MessageAuthor.new(1, "z64")
    new(channel_id, guild_id, content, author, embed)
  end

  def self.new(channel_id, guild_id, content, author, embed)
    channel_id = Discord::Snowflake.new(channel_id.to_u64)
    guild_id = Discord::Snowflake.new(guild_id.to_u64)
    new(channel_id, guild_id, content, author, embed)
  end
end

module StubbedCachedRoutes
  record CachedChannel, guild_id : Discord::Snowflake

  def get_channel(_client, channel_id)
    CachedChannel.new(guild_id: Discord::Snowflake.new(1_u64))
  end
end

class MockClient
  def on_message_create(&block : MessageStub ->)
    block
  end

  def on_message_create(*middleware, &block : MessageStub, Discord::Context ->)
    block
  end

  def create_message(channel_id : Discord::Snowflake, content : String)
    MessageStub.new(channel_id, 1, content)
  end

  def create_message(channel_id : Discord::Snowflake, content : String, embed : Discord::Embed)
    MessageWithEmbedStub.new(channel_id, 1, content, embed)
  end

  def trigger_typing_indicator(channel_id : Discord::Snowflake)
  end
end
