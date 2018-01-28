require "discordcr-middleware"

# Stock middleware used
require "discordcr-middleware/middleware/attribute"
require "discordcr-middleware/middleware/author"
require "discordcr-middleware/middleware/channel"
require "discordcr-middleware/middleware/error"
require "discordcr-middleware/middleware/prefix"

require "redisoid"
require "./hornet/*"

module Hornet
  # Config file
  class_property config = Config.from_yaml(File.read("config.yml"))

  # Discord client
  class_property client = Discord::Client.new(config.token)
  class_property cache = Discord::Cache.new(client)
  @@client.cache = @@cache

  # Handler for initial presence status
  @@client.on_ready do
    if string = @@config.game
      game = Discord::GamePlaying.new(string, 0_i64)
      @@client.status_update("online", game)
    end
  end

  # Redis connection
  class_property redis = Redisoid.new(host: "redis")
end

# Load plugins
require "./hornet/features/*"

Hornet.client.run
