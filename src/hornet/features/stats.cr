module Hornet
  rate_limiter.bucket(:stats, 3_u32, 1.minute)

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
    Flipper.new("stats")) do |payload, ctx|
    stats = GC.stats
    stats_string = String.build do |string|
      string << "```cr\n"
      string << "heap_size:      " << (stats.heap_size / 1024.0 / 1024.0).round(2) << "MB\n"
      string << "free_bytes:     " << (stats.free_bytes / 1024.0 / 1024.0).round(2) << "MB\n"
      string << "unmapped_bytes: " << (stats.unmapped_bytes / 1024.0 / 1024.0).round(2) << "MB\n"
      string << "bytes_since_gc: " << (stats.bytes_since_gc / 1024.0 / 1024.0).round(2) << "MB\n"
      string << "total_bytes:    " << (stats.total_bytes / 1024.0 / 1024.0).round(2) << "MB\n"
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
      payload.channel_id,
      "**bot statistics**",
      Discord::Embed.new(
        description: "**uptime:** `#{Time.now - START_TIME}`",
        fields: [stats_field, cache_field, dispatch_field]))
  end
end
