require "discordcr-middleware/middleware/cached_routes"

module Hornet
  # Plugin for toggling features per-guild
  class Flipper < Discord::Middleware
    include DiscordMiddleware::CachedRoutes

    # Redis namespace
    PATH = "hornet:flipper"

    class_property features = Set(String).new

    # Enable a feature
    def self.enable(name : String, id : UInt64)
      Hornet.redis.set("#{PATH}:#{name}:#{id}", 1)
      Discord::LOGGER.info "[flipper enable] #{name} #{id}"
    end

    # Disable a feature
    def self.disable(name : String, id : UInt64)
      Hornet.redis.del("#{PATH}:#{name}:#{id}")
      Discord::LOGGER.info "[flipper disable] #{name} #{id}"
    end

    def initialize(name : String)
      @redis_key = "#{PATH}:#{name}"
      @@features << name
    end

    # Check whether this feature is enabled for a particular guild ID
    def enabled_in?(id : UInt64)
      Hornet.redis.get "#{@redis_key}:#{id}"
    end

    def call(ctx : Discord::Context(Discord::Message), done)
      channel = get_channel(ctx.client, ctx.payload.channel_id)
      if guild_id = channel.guild_id
        done.call if enabled_in?(guild_id)
      end
    end
  end
end
