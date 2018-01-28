module Hornet
  client.stack(:ping, Flipper.new("ping")) do |ctx|
    if ctx.message.content == "<@213450769276338177> ping"
      client.create_message(ctx.message.channel_id, "pong")
    end
  end
end
