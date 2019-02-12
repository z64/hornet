# TODO: Move to util
struct Discord::Snowflake
  def self.new(value : Int64)
    new(value.to_u64)
  end
end

# TODO: Move to util
module CustomDBType(T, U)
  def self.from_rs(rs)
    value = rs.read(U)
    T.new(value)
  end
end

# TODO: Move to util
module MaybeCustomDBType(T, U)
  def self.from_rs(rs)
    if value = rs.read
      T.new(value.as(U))
    end
  end
end

module Hornet::GuildTags
  def self.create(guild_id : Discord::Snowflake, owner_id : Discord::Snowflake,
                  name : String, content : String, content_sanitized : String)
    tag_created = false
    DB.transaction do |tx|
      db = tx.connection
      tag_id = db.query_one?(<<-SQL, guild_id, owner_id, name, content, content_sanitized, as: Int32)
        INSERT INTO guild_tags AS tag (guild_id, owner_id, name, content, content_sanitized)
             VALUES ($1, $2, $3, $4, $5)
        ON CONFLICT ON CONSTRAINT guild_tags_guild_id_name_key DO UPDATE
          SET owner_id          = $2,
              content           = $4,
              content_sanitized = $5
        WHERE tag.guild_id      = $1
          AND tag.name          = $3
          AND tag.owner_id IS NULL
        RETURNING tag.tag_id
        SQL

      if tag_id
        db.exec(<<-SQL, tag_id, "create", owner_id)
          INSERT INTO guild_tags_audit_logs (guild_tag_id, action, action_author_id)
               VALUES ($1, $2, $3)
          SQL
        tag_created = true
      end
    end
    tag_created
  end

  def self.get_tag(guild_id : Discord::Snowflake, name : String)
    DB.query_one?(<<-SQL, guild_id, name, as: Tag)
      SELECT guild_id, owner_id, name, locked, content, content_sanitized, times_used
        FROM guild_tags
       WHERE guild_id = $1
         AND name     = $2
      SQL
  end

  def self.get_user_tags(guild_id : Discord::Snowflake, user_id : Discord::Snowflake)
    DB.query_all(<<-SQL, guild_id, user_id, as: Tag)
      SELECT guild_id, owner_id, name, locked, content, content_sanitized, times_used
        FROM guild_tags
       WHERE guild_id = $1
         AND owner_id = $2
       ORDER BY name
      SQL
  end

  def self.get_guild_tags(guild_id : Discord::Snowflake)
    DB.query_all(<<-SQL, guild_id, as: Tag)
      SELECT guild_id, owner_id, name, locked, content, content_sanitized, times_used
        FROM guild_tags
       WHERE guild_id = $1
       ORDER BY name
      SQL
  end

  def self.edit(guild_id : Discord::Snowflake, name : String,
                content : String, content_sanitized : String,
                authority : Discord::Snowflake)
    tag_edited = false
    DB.transaction do |tx|
      db = tx.connection
      tag_id = db.query_one?(<<-SQL, guild_id, name, content, content_sanitized, authority, as: Int32)
        UPDATE guild_tags
           SET content           = $3,
               content_sanitized = $4
         WHERE (guild_id = $1
            AND name     = $2
            AND owner_id = $5)
            OR (guild_id = $1
           AND  name     = $2
           AND  locked   = false)
        RETURNING tag_id
        SQL

      if tag_id
        # TODO: The first element would contain the old content. I haven't decided
        #       if I actually want to do this yet, instead of just comparing between
        #       rows. *shrug*
        action_details = {"", content_sanitized}.to_json
        db.exec(<<-SQL, tag_id, "edit", authority, {"", content_sanitized}.to_json)
          INSERT INTO guild_tags_audit_logs (guild_tag_id, action, action_author_id, action_details)
               VALUES ($1, $2, $3, $4)
          SQL
        tag_edited = true
      end
    end
    tag_edited
  end

  def self.lock(guild_id : Discord::Snowflake, name : String, authority : Discord::Snowflake)
    tag_locked = false
    DB.transaction do |tx|
      db = tx.connection
      tag_id = db.query_one?(<<-SQL, guild_id, name, authority, as: Int32)
        UPDATE guild_tags
           SET locked   = true
         WHERE guild_id = $1
           AND name     = $2
           AND owner_id = $3
        RETURNING tag_id
        SQL

      if tag_id
        db.exec(<<-SQL, tag_id, "lock", authority)
          INSERT INTO guild_tags_audit_logs (guild_tag_id, action, action_author_id)
               VALUES ($1, $2, $3)
          SQL
        tag_locked = true
      end
    end
    tag_locked
  end

  def self.unlock(guild_id : Discord::Snowflake, name : String, authority : Discord::Snowflake)
    tag_unlocked = false
    DB.transaction do |tx|
      db = tx.connection
      tag_id = db.query_one?(<<-SQL, guild_id, name, authority, as: Int32)
        UPDATE guild_tags
           SET locked   = false
         WHERE guild_id = $1
           AND name     = $2
           AND owner_id = $3
        RETURNING tag_id
        SQL

      if tag_id
        db.exec(<<-SQL, tag_id, "unlock", authority)
        INSERT INTO guild_tags_audit_logs (guild_tag_id, action, action_author_id)
             VALUES ($1, $2, $3)
        SQL
        tag_unlocked = true
      end
    end
    tag_unlocked
  end

  def self.transfer(guild_id : Discord::Snowflake, name : String,
                    owner_id : Discord::Snowflake?, authority : Discord::Snowflake)
    tag_transferred = false
    DB.transaction do |tx|
      db = tx.connection
      tag_id = db.query_one?(<<-SQL, guild_id, name, owner_id, authority, as: Int32)
        WITH original_owner_id AS (
          SELECT owner_id
            FROM guild_tags
           WHERE guild_id = $1
             AND name     = $2
        )
        UPDATE guild_tags
           SET owner_id = $3
         WHERE guild_id = $1
           AND name     = $2
           AND $4 IN (SELECT owner_id FROM original_owner_id)
        RETURNING tag_id
        SQL

      if tag_id
        action_details = {authority, owner_id}.to_json
        db.exec(<<-SQL, tag_id, "transfer", authority, action_details)
          INSERT INTO guild_tags_audit_logs (guild_tag_id, action, action_author_id, action_details)
               VALUES ($1, $2, $3, $4)
          SQL
        tag_transferred = true
      end
    end
    tag_transferred
  end

  def self.delete(guild_id : Discord::Snowflake, name : String, authority : Discord::Snowflake)
    tag_deleted = false
    DB.transaction do |tx|
      db = tx.connection
      tag_id = db.query_one?(<<-SQL, guild_id, name, as: Int32)
        UPDATE guild_tags
           SET owner_id          = null,
               content           = null,
               content_sanitized = null
         WHERE guild_id = $1
           AND name     = $2
        RETURNING tag_id
        SQL

      if tag_id
        db.exec(<<-SQL, tag_id, "delete", authority)
        INSERT INTO guild_tags_audit_logs (guild_tag_id, action, action_author_id)
             VALUES ($1, $2, $3)
        SQL
        tag_deleted = true
      end
    end
    tag_deleted
  end

  def self.audit_tag(guild_id : Discord::Snowflake, name : String,
                     limit : Int32 = 5)
    DB.query_all(<<-SQL, guild_id, name, limit, as: AuditLogEntry)
      SELECT tag.guild_id, tag.name,
             entry.action::text, entry.action_time, entry.action_author_id, entry.action_details
        FROM guild_tags_audit_logs AS entry
        JOIN guild_tags AS tag
          ON entry.guild_tag_id = tag.tag_id
       WHERE tag.guild_id       = $1
         AND tag.name           = $2
       ORDER BY entry.audit_id DESC
       LIMIT $3
      SQL
  end

  struct Tag
    DB.mapping(
      guild_id: {type: Discord::Snowflake, converter: CustomDBType(Discord::Snowflake, Int64)},
      owner_id: {type: Discord::Snowflake?, converter: MaybeCustomDBType(Discord::Snowflake, Int64)},
      name: String,
      locked: Bool,
      content: String?,
      content_sanitized: String?,
      times_used: Int32
    )

    getter! owner_id
    getter! content
    getter! content_sanitized

    def deleted?
      @owner_id.nil? && @content.nil? && @content_sanitized.nil?
    end
  end

  enum AuditLogAction
    Create
    Edit
    Lock
    Unlock
    Transfer
    Delete

    def self.new(value : String)
      AuditLogAction.parse(value)
    end
  end

  struct AuditLogEntry
    DB.mapping(
      guild_id: {type: Discord::Snowflake, converter: CustomDBType(Discord::Snowflake, Int64)},
      name: String,
      action: {type: AuditLogAction, converter: CustomDBType(AuditLogAction, String)},
      action_time: Time,
      action_author_id: {type: Discord::Snowflake, converter: CustomDBType(Discord::Snowflake, Int64)},
      action_details: JSON::Any
    )
  end
end
