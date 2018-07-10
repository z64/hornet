require "discordcr-middleware/middleware/cached_routes"

module Hornet
  # Plugin for toggling features per-guild
  class Flipper
    include DiscordMiddleware::CachedRoutes

    # Redis namespace
    PATH = "hornet:flipper"

    class_property features = Set(String).new

    # Enable a feature
    def self.enable(name : String, id : Discord::Snowflake | UInt64)
      Hornet.redis.set("#{PATH}:#{name}:#{id}", 1)
      Hornet.logger.info "[flipper enable] #{name} #{id}"
    end

    # Disable a feature
    def self.disable(name : String, id : Discord::Snowflake | UInt64)
      Hornet.redis.del("#{PATH}:#{name}:#{id}")
      Hornet.logger.info "[flipper disable] #{name} #{id}"
    end

    def initialize(name : String)
      @redis_key = "#{PATH}:#{name}"
      @@features << name
    end

    # Check whether this feature is enabled for a particular guild ID
    def enabled_in?(id : Discord::Snowflake | UInt64)
      Hornet.redis.get "#{@redis_key}:#{id}"
    end

    def call(payload, context)
      client = context[Discord::Client]
      channel = get_channel(client, payload.channel_id)
      if guild_id = channel.guild_id
        yield if enabled_in?(guild_id)
      end
    end
  end
end
