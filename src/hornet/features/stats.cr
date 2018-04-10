module Hornet
  rate_limiter.bucket(:stats, 3_u32, 1.minute)

  # Clear data from previous session
  redis.del("hornet:stats:dispatch")

  client.on_dispatch do |event|
    name, _ = event
    redis.hincrby("hornet:stats:dispatch", name, 1)
  end

  client.on_message_create(
    DiscordMiddleware::Prefix.new("<@213450769276338177> \u{1f4be}"),
    DiscordMiddleware::RateLimiter.new(
      rate_limiter,
      :stats,
      DiscordMiddleware::RateLimiterKey::UserID),
    Flipper.new("stats")) do |ctx|
    stats = GC.stats
    stats_string = String.build do |string|
      string << "```cr\n"
      string << "heap_size:      " << stats.heap_size << "\n"
      string << "free_bytes:     " << stats.free_bytes << "\n"
      string << "unmapped_bytes: " << stats.unmapped_bytes << "\n"
      string << "bytes_since_gc: " << stats.bytes_since_gc << "\n"
      string << "total_bytes:    " << stats.total_bytes << "\n"
      string << "```"
    end
    stats_field = Discord::EmbedField.new(
      "gc stats",
      stats_string,
      true)

    total_members = cache.members.map { |_guild, members| members.size }.sum
    cache_string = String.build do |string|
      string << "```cr\n"
      string << "users:       " << cache.users.size << "\n"
      string << "channels:    " << cache.channels.size << "\n"
      string << "guilds:      " << cache.guilds.size << "\n"
      string << "members:     " << total_members << "\n"
      string << "roles:       " << cache.roles.size << "\n"
      string << "dm_channels: " << cache.dm_channels.size << "\n"
      string << "```"
    end
    cache_field = Discord::EmbedField.new(
      "cache totals",
      cache_string,
      true)

    dispatch_stats = redis.hgetall("hornet:stats:dispatch")

    max_len = 0
    index = 0
    dispatch_stats.each do |value|
      unless index.odd?
        string = value.as(String)
        max_len = string.size if string.size > max_len
      end
      index += 1
    end

    dispatch_string = String.build do |string|
      string << "```cr\n"
      index = 0
      while key = dispatch_stats[index]?
        key = key.as(String)
        string << key << ": "
        padding = max_len - key.size
        padding.times { string << ' ' }
        string << dispatch_stats[index + 1] << "\n"
        index += 2
      end
      string << "```"
    end
    dispatch_field = Discord::EmbedField.new(
      "dispatch stats",
      dispatch_string)

    client.create_message(
      ctx.payload.channel_id,
      "**bot statistics**",
      Discord::Embed.new(fields: [stats_field, cache_field, dispatch_field]))
  end
end
