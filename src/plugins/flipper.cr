@[Discord::Plugin::Options(middleware: {DiscordMiddleware::Error.new("error: `%exception%`"),
                                        DiscordMiddleware::Author.new(Hornet::OWNER_ID),
                                        DiscordMiddleware::Prefix.new("flipper")})]
class Hornet::FlipperManager
  include Discord::Plugin
  delegate enable, disable, features, to: Flipper

  @[Discord::Handler(event: :message_create)]
  def handle(payload, _ctx)
    if payload.content == "flipper list"
      reply = client.create_message(payload.channel_id, <<-MESSAGE)
        available features:
        ```cr
        #{features}
        ```
        MESSAGE
      return reply
    end

    args = payload.content.split(' ', remove_empty: true)

    if args.size < 4
      reply = client.create_message(
        payload.channel_id,
        "insufficient arguments (`action`, `name`, `id`)")
      return reply
    end

    _, action, name, guild_id = args
    guild_id = guild_id.to_u64
    reply = case action
            when "enable"
              enable(name, guild_id)
              "enabled `#{name}` in `#{guild_id}`"
            when "disable"
              disable(name, guild_id)
              "disabled `#{name}` in `#{guild_id}`"
            else
              "unknown flipper command: `#{action}`"
            end
    client.create_message(payload.channel_id, reply)
  end
end
