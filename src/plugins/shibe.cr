@[Discord::Plugin::Options(middleware: DiscordMiddleware::Error.new("error: `%exception%`"))]
class Hornet::Shibe
  include Discord::Plugin

  SHIBE_URL = "http://shibe.online/api"
  @urls = Hash(String, Array(String)).new { |h, k| h[k] = Array(String).new }

  def next_url(kind = "shibes")
    if @urls[kind].empty?
      @urls[kind] = fetch_urls(kind)
      next_url(kind)
    else
      @urls[kind].shift
    end
  end

  def fetch_urls(kind)
    response = HTTP::Client.get(SHIBE_URL + "/#{kind}?limit=100")
    Array(String).from_json(response.body)
  end

  def send_image(channel_id, url)
    embed = Discord::Embed.new(title: "link", url: url,
      image: Discord::EmbedImage.new(url: url), colour: 0xc5be8a)
    client.create_message(channel_id, "", embed)
  end

  ShibeFlipper = Flipper.new("shibe")

  @[Discord::Handler(event: :message_create, middleware: {Hornet::CommandSpec.new("shibe", "shibe", max_args: 0), ShibeFlipper})]
  def shibe(payload, _ctx)
    url = next_url("shibes")
    send_image(payload.channel_id, url)
  end

  @[Discord::Handler(event: :message_create, middleware: {Hornet::CommandSpec.new("cat", "cat", max_args: 0), ShibeFlipper})]
  def cat(payload, _ctx)
    url = next_url("cats")
    send_image(payload.channel_id, url)
  end

  @[Discord::Handler(event: :message_create, middleware: {Hornet::CommandSpec.new("bird", "bird", max_args: 0), ShibeFlipper})]
  def bird(payload, _ctx)
    url = next_url("birds")
    send_image(payload.channel_id, url)
  end
end
