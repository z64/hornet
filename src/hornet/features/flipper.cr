module Hornet
  client.stack(:flipper,
    DiscordMiddleware::Error.new("error: `%exception%`"),
    DiscordMiddleware::Author.new(config.owner),
    DiscordMiddleware::Prefix.new("flipper")) do |ctx|
    message = ctx.message.content

    if message == "flipper list"
      client.create_message(
        ctx.message.channel_id,
        "available features: ```cr\n#{Flipper.features.to_a}\n```")
      next
    end

    args = message.split(' ', remove_empty: true)

    if args.size < 4
      client.create_message(
        ctx.message.channel_id,
        "insuffienct arguments (`action`, `name`, `id`)")
      next
    end

    _, action, name, id = args
    id = id.to_u64

    unless Flipper.features.includes?(name)
      client.create_message(
        ctx.message.channel_id,
        "unknown feature: `#{name}`")
      next
    end

    unless cache.guilds.map(&.[](0)).includes?(id)
      client.create_message(
        ctx.message.channel_id,
        "unknown guild ID: `#{id}`")
      next
    end

    case action
    when "enable"
      Flipper.enable(name, id)
      client.create_message(
        ctx.message.channel_id,
        "enabled `#{name}` in `#{id}`")
    when "disable"
      Flipper.disable(name, id)
      client.create_message(
        ctx.message.channel_id,
        "disabled `#{name}` in `#{id}`")
    else
      client.create_message(
        ctx.message.channel_id,
        "unknown action")
    end
  end
end
