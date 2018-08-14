require "discordcr-plugin"
require "pg"

require "./database/*"
require "./middleware/*"
require "./plugins/*"

module Hornet
  class Shard
    getter client : Discord::Client
    getter cache : Discord::Cache
    delegate run, to: client

    def initialize
      @client = Discord::Client.new(ENV["HORNET_TOKEN"])
      @cache = Discord::Cache.new(@client)
      @client.cache = @cache
      register_plugins
    end

    def register_plugins
      Discord::Plugin.plugins.each do |plugin|
        client.register(plugin)
      end
    end
  end

  DB = PG.connect(ENV["HORNET_DB_URL"])

  def self.run(argv : Array(String))
    shard = Shard.new
    shard.run
  end

  def self.configure_plugins
    file = File.open("config.json", "r")
    parser = JSON::PullParser.new(file)
    parser.read_object do |key|
      Discord::Plugin.plugins.each do |plugin|
        if plugin.class.to_s.underscore == key
          plugin.configure(parser)
        else
          parser.skip
        end
      end
    end
    file.close
  end
end
