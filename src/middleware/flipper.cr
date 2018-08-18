class Hornet::Flipper
  include DiscordMiddleware::CachedRoutes

  class_getter features = Array(String).new

  def self.enable(feature : String, guild_id : Discord::Snowflake | UInt64)
    FlipperSettings.update(feature, guild_id, true)
  end

  def self.disable(feature : String, guild_id : Discord::Snowflake | UInt64)
    FlipperSettings.update(feature, guild_id, false)
  end

  def initialize(@name : String)
    @@features << @name
  end

  def call(payload, ctx)
    client = ctx[Discord::Client]
    if guild_id = get_channel(client, payload.channel_id).guild_id
      enabled = FlipperSettings.get(@name, guild_id) || false
      yield if enabled
    end
  end
end
