@[Discord::Plugin::Options(middleware: {DiscordMiddleware::Error.new("error: `%exception%`"),
                                        DiscordMiddleware::Author.new(Hornet::OWNER_ID)})]
class Hornet::FlipperManager
  include Discord::Plugin
  delegate enable, disable, features, to: Flipper

  @[Discord::Handler(event: :message_create, middleware: Hornet::CommandSpec.new("flipper", "flipper <list, enable, disable> [feature name] [guild ID]", min_args: 1, max_args: 3))]
  def handle(payload, ctx)
    args = ctx[Hornet::CommandParser::ParsedCommand]

    return client.create_message(payload.channel_id, <<-MESSAGE) if args[0].to_s == "list"
      available features:
      ```cr
      #{features}
      ```
      MESSAGE

    feature_name = args[1].to_s
    return client.create_message(payload.channel_id, "unknown feature: `#{feature_name}`") unless features.includes?(feature_name)

    guild_id = args[2].to_snowflake
    reply = if args[0].to_bool
              enable(feature_name, guild_id)
              "enabled `#{feature_name}` in `#{guild_id}`"
            else
              disable(feature_name, guild_id)
              "disabled `#{feature_name}` in `#{guild_id}`"
            end
    client.create_message(payload.channel_id, reply)
  end
end
