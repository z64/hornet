require "spec"
require "../src/hornet"

record MessageStub, channel_id : UInt64, content : String

class MockClient
  def on_message_create(&block : MessageStub ->)
    block
  end

  def on_message_create(_middleware, &block : MessageStub, Symbol ->)
    block
  end

  def create_message(channel_id : UInt64, content : String)
    MessageStub.new(channel_id, content)
  end
end
