require "../spec_helper"

private def with_tags
  yield
ensure
  Hornet::DB.exec("DELETE FROM guild_tags_audit_logs")
  Hornet::DB.exec("DELETE FROM guild_tags")
end

@[Discord::Plugin::Options(client_class: MockClient, middleware: true)]
class Hornet::GuildTagsManager
  include Discord::Plugin
end

describe Hornet::GuildTagsManager do
  client = MockClient.new
  plugin = Hornet::GuildTagsManager.new
  plugin.register_on(client)

  guild_id = Discord::Snowflake.new(1_u64)
  channel_id = Discord::Snowflake.new(1_u64)
  owner_id = Discord::Snowflake.new(1_u64)

  it "create" do
    with_tags do
      payload = MessageStub.new(1, 1, "tag create foo bar baz")
      ctx = {Hornet::CommandParser::ParsedCommand => Hornet::CommandParser.parse(payload.content.lchop("tag"))}
      expected = MessageStub.new(1, 1, %(created tag "foo"))
      plugin.handle_message(payload, ctx).should eq expected

      expected = MessageStub.new(1, 1, %(tag "foo" already exists))
      plugin.handle_message(payload, ctx).should eq expected
    end
  end

  it "edit" do
    with_tags do
      plugin.create(guild_id, owner_id, "foo", "content", "sanitized")

      payload = MessageStub.new(1, 1, "tag edit foo bar bang")
      ctx = {Hornet::CommandParser::ParsedCommand => Hornet::CommandParser.parse(payload.content.lchop("tag"))}
      expected = MessageStub.new(1, 1, %(edited tag "foo"))
      plugin.handle_message(payload, ctx).should eq expected

      plugin.unlock(guild_id, "foo", owner_id)
      payload = MessageStub.new(1, 1, "tag edit foo bar buzz", MessageAuthor.new(2, "pixel"))
      ctx = {Hornet::CommandParser::ParsedCommand => Hornet::CommandParser.parse(payload.content.lchop("tag"))}
      expected = MessageStub.new(1, 1, %(edited tag "foo"))
      plugin.handle_message(payload, ctx).should eq expected

      plugin.delete(guild_id, "foo", owner_id)
      expected = MessageStub.new(1, 1, %(failed to edit tag "foo". it doesn't exist, or you don't own it))
      plugin.handle_message(payload, ctx).should eq expected
    end
  end

  it "lock" do
    with_tags do
      plugin.create(guild_id, owner_id, "foo", "content", "sanitized")

      payload = MessageStub.new(1, 1, "tag lock foo")
      ctx = {Hornet::CommandParser::ParsedCommand => Hornet::CommandParser.parse(payload.content.lchop("tag"))}
      expected = MessageStub.new(1, 1, %(locked tag "foo"))
      plugin.handle_message(payload, ctx).should eq expected

      plugin.delete(guild_id, "foo", owner_id)
      expected = MessageStub.new(1, 1, %(failed to lock tag "foo". it doesn't exist, or you don't own it))
      plugin.handle_message(payload, ctx).should eq expected
    end
  end

  it "unlock" do
    with_tags do
      plugin.create(guild_id, owner_id, "foo", "content", "sanitized")

      payload = MessageStub.new(1, 1, "tag unlock foo")
      ctx = {Hornet::CommandParser::ParsedCommand => Hornet::CommandParser.parse(payload.content.lchop("tag"))}
      expected = MessageStub.new(1, 1, %(unlocked tag "foo"))
      plugin.handle_message(payload, ctx).should eq expected

      plugin.delete(guild_id, "foo", owner_id)
      expected = MessageStub.new(1, 1, %(failed to unlock tag "foo". it doesn't exist, or you don't own it))
      plugin.handle_message(payload, ctx).should eq expected
    end
  end

  pending "transfer"

  it "delete" do
    with_tags do
      plugin.create(guild_id, owner_id, "foo", "content", "sanitized")

      payload = MessageStub.new(1, 1, "tag delete foo")
      ctx = {Hornet::CommandParser::ParsedCommand => Hornet::CommandParser.parse(payload.content.lchop("tag"))}
      expected = MessageStub.new(1, 1, %(deleted tag "foo"))
      plugin.handle_message(payload, ctx).should eq expected

      expected = MessageStub.new(1, 1, %(failed to delete tag "foo". it doesn't exist, or you don't own it))
      plugin.handle_message(payload, ctx).should eq expected
    end
  end

  it "info" do
    with_tags do
      plugin.create(guild_id, owner_id, "foo", "content", "sanitized")
      plugin.edit(guild_id, "foo", "content", "sanitized", owner_id)

      payload = MessageStub.new(1, 1, "tag info foo")
      ctx = {Hornet::CommandParser::ParsedCommand => Hornet::CommandParser.parse(payload.content.lchop("tag"))}
      expected = MessageStub.new(1, 1, <<-MESSAGE)
      **tag info**
      ```toml
      [tag    ] foo
      [author ] @z64#1337
      [created] 2019-03-05 03:33:00 UTC
      ```
      **tag history**
      ```toml
      [created] @z64#1337 (2019-03-05 03:33:00 UTC)
      [edited ] @z64#1337 (2019-03-05 03:33:00 UTC)
      ```
      MESSAGE

      plugin.handle_message(payload, ctx).should eq expected
    end
  end

  pending "list"

  it "get" do
    with_tags do
      plugin.create(guild_id, owner_id, "foo", "content", "sanitized")

      payload = MessageStub.new(1, 1, "tag foo")
      ctx = {Hornet::CommandParser::ParsedCommand => Hornet::CommandParser.parse(payload.content.lchop("tag"))}
      expected = MessageStub.new(1, 1, %(sanitized))
      plugin.handle_message(payload, ctx).should eq expected

      payload = MessageStub.new(1, 1, "tag bar")
      ctx = {Hornet::CommandParser::ParsedCommand => Hornet::CommandParser.parse(payload.content.lchop("tag"))}
      expected = MessageStub.new(1, 1, %(tag "bar" not found))
      plugin.handle_message(payload, ctx).should eq expected
    end
  end
end
