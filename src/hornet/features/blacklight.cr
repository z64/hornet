module Hornet
  # Container for Blacklight's guild constants
  module BlacklightSnowflake
    # Server ID
    Guild = 178852528144777218_u64

    # Channel for move logs
    LogChannel = 402364303245705226_u64

    # Channel to move "dead" users to
    TargetChannel = 402547172861673492_u64

    # Roles that can move members
    MoveRoles = {
      # devs
      389982256833495060_u64,

      # SWTOR HR
      314629171315998730_u64,

      # FFXIV officers
      314631333236441089_u64,

      # SWTOR officers
      334057003049680897_u64,
    }
  end

  # Emoji
  GreenTick = "<:greentick:407025903936471041>"
  RedTick   = "<:redtick:407025904028614657>"

  # !move <@!id>
  client.on_message_create(
    DiscordMiddleware::Error.new("error: `%exception%`"),
    DiscordMiddleware::Prefix.new("!dead"),
    DiscordMiddleware::Channel.new(type: 0_u8, guild_id: BlacklightSnowflake::Guild),
    Flipper.new("blacklight.move")) do |ctx|
    unless ctx.payload.mentions.size == 1
      response_id = client.create_message(
        ctx.payload.channel_id,
        "wrong number of arguments. usage: `!move @mention`")
      next
    end

    running_member = cache.resolve_member(
      BlacklightSnowflake::Guild,
      ctx.payload.author.id)

    target_member = cache.resolve_member(
      BlacklightSnowflake::Guild,
      ctx.payload.mentions.first.id)

    response_id = if running_member.roles.any? { |id| BlacklightSnowflake::MoveRoles.includes?(id) }
                    client.modify_guild_member(
                      BlacklightSnowflake::Guild,
                      target_member.user.id,
                      channel_id: BlacklightSnowflake::TargetChannel)

                    success_str =
                      "\u{21aa}\u{fe0f} " \
                      "**#{running_member.user.username}##{running_member.user.discriminator}** " \
                      "moved <@#{target_member.user.id}> to <##{BlacklightSnowflake::TargetChannel}>"

                    client.create_message(
                      BlacklightSnowflake::LogChannel,
                      success_str, Discord::Embed.new(timestamp: Time.now))

                    nil
                  else
                    client.create_message(
                      ctx.payload.channel_id,
                      "#{RedTick} insufficient permissions").id
                  end

    if response_id
      sleep 3
      client.bulk_delete_messages(
        ctx.payload.channel_id,
        [ctx.payload.id, response_id])
    else
      client.delete_message(
        ctx.payload.channel_id,
        ctx.payload.id)
    end
  end
end
