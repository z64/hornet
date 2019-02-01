module Hornet::Sanitizer
  ZWS = "\u200b"

  # TODO: should accept `Shard` here instead of a cache, maybe
  def self.sanitize(message, cache)
    content = message.content
    offset = 0

    Discord::Mention.parse(message.content) do |mention|
      sanitized = nil
      case mention
      when Discord::Mention::User
        if valid_user = message.mentions.find { |m| m.id == mention.id }
          sanitized = "@#{valid_user.username}##{valid_user.discriminator}"
        else
          sanitized = "@unknown-user"
        end
      when Discord::Mention::Role
        begin
          if message.mention_roles.includes?(mention.id)
            guild = cache.resolve_guild(message.guild_id.not_nil!)
            if valid_role = guild.roles.find { |r| r.id == mention.id }
              sanitized = "@#{valid_role.name}"
            else
              sanitized = "@unknown-role"
            end
          else
            sanitized = "@unknown-role"
          end
        rescue
          sanitized = "@unknown-role"
        end
      when Discord::Mention::Channel
        begin
          if message.guild_id
            mentioned_channel = cache.resolve_channel(mention.id)
            sanitized = "##{mentioned_channel.name}"
          else
            sanitized = "#unknown-channel"
          end
        rescue
          sanitized = "#unknown-channel"
        end
      when Discord::Mention::Emoji
        # Nothing
      when Discord::Mention::Everyone
        sanitized = "@#{ZWS}everyone"
      when Discord::Mention::Here
        sanitized = "@#{ZWS}here"
      end

      if sanitized
        mention_start = mention.start - offset
        mention_end = mention_start + mention.size - 1

        # BUG(upstream): discordcr role mention ends are off by one
        mention_end += 1 if mention.is_a?(Discord::Mention::Role)

        content = content.sub(mention_start..mention_end, sanitized)
        offset = message.content.size - content.size
      end
    end

    content
  end
end
