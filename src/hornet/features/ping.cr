module Hornet
  client.on_message_create(Flipper.new("ping")) do |ctx|
    if ctx.payload.content == "<@213450769276338177> \u{1f3d3}"
      message = nil
      time = Time.measure do
        message = client.create_message(ctx.payload.channel_id, "\u{1f3d3}")
      end

      client.edit_message(ctx.payload.channel_id, message.as(Discord::Message).id, "\u{1f3d3} `#{time}`")
    end
  end
end
