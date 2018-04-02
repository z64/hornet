module Hornet
  rate_limiter.bucket(:fortune, 3_u32, 1.minute)

  client.on_message_create(
    DiscordMiddleware::Error.new("error: `%exception%`"),
    DiscordMiddleware::Prefix.new("<@213450769276338177> fortune"),
    Flipper.new("fortune"),
    DiscordMiddleware::RateLimiter.new(
      rate_limiter,
      :fortune,
      DiscordMiddleware::RateLimiterKey::ChannelID)) do |ctx|
    str = `/usr/games/fortune -c`

    cookie, _, fortune = str.split("\n", 3)

    ctx.client.create_message(
      ctx.payload.channel_id,
      "",
      Discord::Embed.new(description: fortune, title: cookie))
  end
end
