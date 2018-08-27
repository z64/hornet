require "../spec_helper"

@[Discord::Plugin::Options(client_class: MockClient)]
class Hornet::PagedMessage
  include Discord::Plugin
end

describe Hornet::PagedMessage::Controller do
  data = {
    Hornet::PagedMessage::Page.new("foo", nil),
    Hornet::PagedMessage::Page.new("bar", nil),
    Hornet::PagedMessage::Page.new("baz", nil),
  }

  it "#next_page" do
    controller = Hornet::PagedMessage::Controller.new(1, 2, 3) do |index|
      data[index]?
    end

    data.each do |page|
      controller.next_page.should eq page
    end

    controller.next_page.should be_nil
  end

  it "#previous_page" do
    controller = Hornet::PagedMessage::Controller.new(1, 2, 3) do |index|
      data[index]
    end

    # TODO: another spec
    controller.previous_page.should eq data[0]
    controller.previous_page.should eq data[0]

    3.times { controller.next_page }
    data.reverse_each do |page|
      controller.previous_page.should eq page
    end
  end
end

describe Hornet::PagedMessage do
  client = MockClient.new
  plugin = Hornet::PagedMessage.new
  plugin.register_on(client)

  next_emoji = Discord::ReactionEmoji.from_json(%({"name":"#{Hornet::PagedMessage::NEXT_PAGE_EMOJI}"}))
  previous_emoji = Discord::ReactionEmoji.from_json(%({"name":"#{Hornet::PagedMessage::PREVIOUS_PAGE_EMOJI}"}))

  describe "#handle" do
    it "edits message with next page" do
      data = {
        Hornet::PagedMessage::Page.new("foo", nil),
        Hornet::PagedMessage::Page.new("bar", nil),
        Hornet::PagedMessage::Page.new("baz", nil),
      }

      controller = Hornet::PagedMessage::Controller.new(1, 2, 3) do |index|
        data[index]
      end

      plugin.controllers.push(controller)

      data.each do |page|
        payload = MessageReactionStub.new(1, 2, 3, next_emoji)
        expected = MessageStub.new(1, page.content, nil)
        result = plugin.handle(payload)
        result.should eq expected
      end

      plugin.controllers.pop
    end

    it "edits message with previous page" do
      data = {
        Hornet::PagedMessage::Page.new("foo", nil),
        Hornet::PagedMessage::Page.new("bar", nil),
        Hornet::PagedMessage::Page.new("baz", nil),
      }

      controller = Hornet::PagedMessage::Controller.new(1, 2, 3) do |index|
        data[index]
      end

      plugin.controllers.push(controller)
      3.times { controller.next_page }

      data.reverse_each do |page|
        payload = MessageReactionStub.new(1, 2, 3, previous_emoji)
        expected = MessageStub.new(1, page.content, nil)
        result = plugin.handle(payload)
        result.should eq expected
      end

      plugin.controllers.pop
    end

    it "ignores payload with no registered controller" do
      payload = MessageReactionStub.new(3, 2, 3, next_emoji)
      plugin.handle(payload).should be_nil
    end
  end
end
