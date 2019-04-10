@[Discord::Plugin::Options(middleware: DiscordMiddleware::Error.new("error: `%exception%`"))]
class Hornet::GuildTagsManager
  include Discord::Plugin
  delegate create, edit, lock, unlock, transfer, delete, get_tag, audit_tag, to: GuildTags
  delegate sanitize, to: Sanitizer

  @[Discord::Handler(event: :message_create, middleware: {Hornet::CommandSpec.new("tag", "(you shout into the void, and hear not even an echo)", min_args: 1),
                                                          Hornet::Flipper.new("guild_tags")})]
  def handle_message(payload, ctx)
    args = ctx[CommandParser::ParsedCommand]

    guild_id = payload.guild_id
    return unless guild_id

    case args[0].to_s
    when "create"
      name = args[1].to_s

      # TODO: glob implementation
      args[2] # assert tag content present
      index = payload.content.rindex(name).not_nil! + name.size
      tag_content = payload.content[index..-1].strip
      tag_content_sanitized = tag_content # TODO: sanitizer

      owner_id = payload.author.id

      created = create(guild_id, owner_id, name, tag_content, tag_content_sanitized)
      reply = if created
                %(created tag "#{name}")
              else
                %(tag "#{name}" already exists)
              end
      client.create_message(payload.channel_id, reply)
    when "edit"
      name = args[1].to_s

      # TODO: glob implementation
      args[2] # assert tag content present
      index = payload.content.rindex(name).not_nil! + name.size
      tag_content = payload.content[index..-1].strip
      tag_content_sanitized = tag_content # TODO: sanitizer

      authority = payload.author.id

      edited = edit(guild_id, name, tag_content, tag_content_sanitized, authority)
      reply = if edited
                %(edited tag "#{name}")
              else
                %(failed to edit tag "#{name}". it doesn't exist, or you don't own it)
              end
      client.create_message(payload.channel_id, reply)
    when "lock"
      name = args[1].to_s
      authority = payload.author.id
      locked = lock(guild_id, name, authority)
      reply = if locked
                %(locked tag "#{name}")
              else
                %(failed to lock tag "#{name}". it doesn't exist, or you don't own it)
              end
      client.create_message(payload.channel_id, reply)
    when "unlock"
      name = args[1].to_s
      authority = payload.author.id
      unlocked = unlock(guild_id, name, authority)
      reply = if unlocked
                %(unlocked tag "#{name}")
              else
                %(failed to unlock tag "#{name}". it doesn't exist, or you don't own it)
              end
      client.create_message(payload.channel_id, reply)
    when "transfer"
      # TODO
    when "delete"
      name = args[1].to_s
      authority = payload.author.id
      deleted = delete(guild_id, name, authority)
      reply = if deleted
                %(deleted tag "#{name}")
              else
                %(failed to delete tag "#{name}". it doesn't exist, or you don't own it)
              end
      client.create_message(payload.channel_id, reply)
    when "info"
      name = args[1].to_s
      authority = payload.author.id
      unlocked = unlock(guild_id, name, authority)
      reply = if unlocked
                %(unlocked tag "#{name}")
              else
                %(failed to unlock tag "#{name}". it doesn't exist, or you don't own it)
              end
      client.create_message(payload.channel_id, reply)
    when "list"
      # TODO: wait for paginator, probably.
    else
      index = payload.content.rindex("tag").not_nil! + 3
      name = payload.content[index..-1].strip
      tag = get_tag(guild_id, name, use: true)
      reply = if tag
                tag.content_sanitized
              else
                %(tag "#{name}" not found)
              end
      client.create_message(payload.channel_id, reply)
    end
  end

  # @[Discord::Handler(event: :guild_member_delete)]
  # def handle_member_leave(payload, _ctx)
  #   # TODO: clear owner
  # end

  # @[Discord::Handler(event: :guild_delete)]
  # def handle_guild_leave(payload, _ctx)
  #   # Ignore unavailable guilds
  #   return if payload.unavailable
  #   # TODO: clear tags
  # end
end
