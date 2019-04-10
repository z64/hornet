require "../spec_helper"

private def with_tags
  yield
ensure
  Hornet::DB.exec("DELETE FROM guild_tags_audit_logs")
  Hornet::DB.exec("DELETE FROM guild_tags")
end

describe Hornet::GuildTags do
  guild_id = Discord::Snowflake.new(1_u64)
  owner_id = Discord::Snowflake.new(2_u64)

  it "create" do
    with_tags do
      Hornet::GuildTags.create(guild_id, owner_id, "name", "content", "sanitized").should be_true
      Hornet::GuildTags.create(guild_id, owner_id, "name", "content", "sanitized").should be_false
      Hornet::GuildTags.delete(guild_id, "name", owner_id)
      Hornet::GuildTags.create(guild_id, owner_id, "name", "content", "sanitized").should be_true
    end
  end

  it "get" do
    with_tags do
      Hornet::GuildTags.create(guild_id, owner_id, "name", "content", "sanitized")
      tag = Hornet::GuildTags.get_tag(guild_id, "name", use: true)
      tag.should be_a Hornet::GuildTags::Tag
      tag = tag.as(Hornet::GuildTags::Tag)
      tag.guild_id.should eq guild_id
      tag.owner_id.should eq owner_id
      tag.content.should eq "content"
      tag.content_sanitized.should eq "sanitized"
      tag.locked.should be_true
      tag.times_used.should eq 1
      tag.created_at.should be_a Time

      tag = Hornet::GuildTags.get_tag(guild_id, "name", use: true)
      tag.not_nil!.times_used.should eq 2
    end
  end

  it "list user tags" do
    with_tags do
      Hornet::GuildTags.create(guild_id, owner_id, "b", "content", "sanitized")
      Hornet::GuildTags.create(guild_id, owner_id, "a", "content", "sanitized")
      Hornet::GuildTags.create(guild_id, owner_id, "c", "content", "sanitized")

      other_id = Discord::Snowflake.new(69_u64)
      Hornet::GuildTags.create(guild_id, other_id, "d", "content", "sanitized")

      tags = Hornet::GuildTags.get_user_tags(guild_id, owner_id)
      tags.map(&.name).should eq ["a", "b", "c"]
    end
  end

  it "list guild tags" do
    with_tags do
      Hornet::GuildTags.create(guild_id, Discord::Snowflake.new(1_u64), "b", "content", "sanitized")
      Hornet::GuildTags.create(guild_id, Discord::Snowflake.new(2_u64), "a", "content", "sanitized")
      Hornet::GuildTags.create(guild_id, Discord::Snowflake.new(3_u64), "c", "content", "sanitized")

      other_id = Discord::Snowflake.new(69_u64)
      Hornet::GuildTags.create(other_id, owner_id, "d", "content", "sanitized")

      tags = Hornet::GuildTags.get_guild_tags(guild_id)
      tags.map(&.name).should eq ["a", "b", "c"]
    end
  end

  it "edit" do
    with_tags do
      Hornet::GuildTags.create(guild_id, owner_id, "name", "content", "sanitized")

      Hornet::GuildTags.edit(guild_id, "name", "new content", "new sanitized", owner_id).should be_true
      tag = Hornet::GuildTags.get_tag(guild_id, "name")
      tag = tag.not_nil!.as(Hornet::GuildTags::Tag)
      tag.content.should eq "new content"
      tag.content_sanitized.should eq "new sanitized"

      other_id = Discord::Snowflake.new(69_u64)
      Hornet::GuildTags.edit(guild_id, "name", "new content", "new sanitized", other_id).should be_false
      Hornet::GuildTags.unlock(guild_id, "name", owner_id)
      Hornet::GuildTags.edit(guild_id, "name", "new content", "new sanitized", other_id).should be_true

      Hornet::GuildTags.delete(guild_id, "name", owner_id)
      Hornet::GuildTags.edit(guild_id, "name", "new content", "new sanitized", owner_id).should be_false
    end
  end

  it "lock/unlock" do
    with_tags do
      Hornet::GuildTags.create(guild_id, owner_id, "name", "content", "sanitized")

      Hornet::GuildTags.unlock(guild_id, "name", owner_id).should be_true
      tag = Hornet::GuildTags.get_tag(guild_id, "name")
      tag = tag.not_nil!.as(Hornet::GuildTags::Tag)
      tag.locked.should be_false

      Hornet::GuildTags.lock(guild_id, "name", owner_id).should be_true
      tag = Hornet::GuildTags.get_tag(guild_id, "name")
      tag = tag.not_nil!.as(Hornet::GuildTags::Tag)
      tag.locked.should be_true

      other_id = Discord::Snowflake.new(69_u64)
      Hornet::GuildTags.lock(guild_id, "name", other_id).should be_false
      Hornet::GuildTags.unlock(guild_id, "name", other_id).should be_false
    end
  end

  it "transfer" do
    with_tags do
      Hornet::GuildTags.create(guild_id, owner_id, "name", "content", "sanitized")

      new_owner_id = Discord::Snowflake.new(3_u64)
      Hornet::GuildTags.transfer(guild_id, "name", new_owner_id, owner_id).should be_true
      tag = Hornet::GuildTags.get_tag(guild_id, "name")
      tag = tag.not_nil!.as(Hornet::GuildTags::Tag)
      tag.owner_id.should eq new_owner_id

      other_id = Discord::Snowflake.new(69_u64)
      Hornet::GuildTags.transfer(guild_id, "name", new_owner_id, other_id).should be_false
    end
  end

  it "delete" do
    with_tags do
      Hornet::GuildTags.create(guild_id, owner_id, "name", "content", "sanitized")

      Hornet::GuildTags.delete(guild_id, "name", owner_id)
      tag = Hornet::GuildTags.get_tag(guild_id, "name").not_nil!
      tag.deleted?.should be_true
      tag.guild_id.should eq guild_id
      tag.name.should eq "name"
    end
  end

  it "audit tag" do
    with_tags do
      Hornet::GuildTags.create(guild_id, owner_id, "name", "content", "sanitized")
      Hornet::GuildTags.unlock(guild_id, "name", owner_id)
      Hornet::GuildTags.edit(guild_id, "name", "new content", "new sanitized", owner_id)

      logs = Hornet::GuildTags.audit_tag(guild_id, "name")
      logs.size.should eq 3

      logs[0].tag_guild_id.should eq guild_id
      logs[0].tag_name.should eq "name"
      logs[0].action.should eq Hornet::GuildTags::AuditLogAction::Edit
      logs[0].action_author_id.should eq owner_id
      logs[0].action_details.should eq JSON.parse(%(["", "new sanitized"]))

      logs[1].tag_guild_id.should eq guild_id
      logs[1].tag_name.should eq "name"
      logs[1].action.should eq Hornet::GuildTags::AuditLogAction::Unlock
      logs[1].action_author_id.should eq owner_id

      logs[2].tag_guild_id.should eq guild_id
      logs[2].tag_name.should eq "name"
      logs[2].action.should eq Hornet::GuildTags::AuditLogAction::Create
      logs[2].action_author_id.should eq owner_id
    end
  end
end
