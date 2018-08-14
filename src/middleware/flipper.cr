class Hornet::Flipper
  include DiscordMiddleware::CachedRoutes

  class_getter store = Hash({String, UInt64}, Bool).new
  class_getter features = Array(String).new

  def self.enable(feature : String, guild_id : Discord::Snowflake | UInt64)
    @@store[{feature, guild_id.to_u64}] = true
  end

  def self.disable(feature : String, guild_id : Discord::Snowflake | UInt64)
    @@store[{feature, guild_id.to_u64}] = false
  end

  def initialize(@name : String)
    @@features << @name
  end

  def call(payload, ctx)
    client = ctx[Discord::Client]
    if guild_id = get_channel(client, payload.channel_id).guild_id
      enabled = @@store[{@name, guild_id}]? || false
      yield if enabled
    end
  end
end
