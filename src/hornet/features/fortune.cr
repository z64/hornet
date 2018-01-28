module Hornet
  client.stack(:fortune,
    Flipper.new("fortune"),
    DiscordMiddleware::Error.new("error: `%exception%`"),
    DiscordMiddleware::Prefix.new("<@213450769276338177> fortune")) do |ctx|
    str = `/usr/games/fortune`
    client.create_message(ctx.message.channel_id, "", Discord::Embed.new(description: str))
  end
end
