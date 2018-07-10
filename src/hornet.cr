require "discordcr-middleware"
require "rate_limiter"

# Stock middleware used
require "discordcr-middleware/middleware/attribute"
require "discordcr-middleware/middleware/author"
require "discordcr-middleware/middleware/cached_routes"
require "discordcr-middleware/middleware/channel"
require "discordcr-middleware/middleware/error"
require "discordcr-middleware/middleware/prefix"
require "discordcr-middleware/middleware/rate_limiter"

require "redisoid"
require "./hornet/*"

module Hornet
  START_TIME = Time.now

  {% begin %}
    class_property config = Config.from_yaml(File.read("config.yml"))
    class_property logger = Logger.new(STDOUT)
    class_property client = Discord::Client.new(config.token, logger: logger)
    class_property cache = Discord::Cache.new(client)
    class_property rate_limiter = RateLimiter(Discord::Snowflake).new
    class_property redis do
      Redisoid.new(host: "redis")
    end
  {% end %}

  client.cache = cache

  @@first_ready = true

  # Handler for initial presence status
  client.on_ready do
    if string = config.game
      game = Discord::GamePlaying.new(string, 0_i64)
      client.status_update("online", game)
    elsif @@first_ready
      @@first_ready = false
      spawn do
        Discord.every(5.minutes) do
          heap = (GC.stats.heap_size / 1024.0 / 1024.0).round(2)
          game = Discord::GamePlaying.new("#{heap}MB", 0_i64)
          client.status_update("online", game)
        end
      end
    end
  end

  def self.run(argv : Array(String))
    # Clear gateway stats from previous run
    redis.del("hornet:stats:dispatch")

    # Start Discord client
    client.run
  end
end

# Load plugins
require "./hornet/features/*"
