@[Discord::Plugin::Options(middleware: {DiscordMiddleware::Error.new("error: `%exception%`"),
                                        DiscordMiddleware::Prefix.new("h>config"),
                                        Hornet::Flipper.new("config")})]
class Hornet::ConfigManager
  include Discord::Plugin

  @[Discord::Handler(event: :message_create)]
  def reload(payload, _ctx)
    return unless payload.content == "h>config reload"
    Hornet.configure_plugins
    client.create_message(payload.channel_id, "done")
  end

  @[Discord::Handler(event: :message_create)]
  def show(payload, _ctx)
    return unless payload.content == "h>config show"
    json = File.read("config.json")
    client.create_message(payload.channel_id, "```json\n#{json}```")
  end
end
