module Hornet
  client.stack(:ping, Flipper.new("ping")) do |ctx|
    if ctx.message.content == "<@213450769276338177> \u{1f3d3}"
      message = nil
      time = Time.measure do
        message = client.create_message(ctx.message.channel_id, "\u{1f3d3}")
      end

      client.edit_message(ctx.message.channel_id, message.as(Discord::Message).id, "\u{1f3d3} `#{time}`")
    end
  end
end
