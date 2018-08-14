@[Discord::Plugin::Options(middleware: {DiscordMiddleware::Error.new("error: `%exception%`"),
                                        DiscordMiddleware::Prefix.new("<@#{CLIENT_ID}> shibe"),
                                        Hornet::Flipper.new("shibe")})]
class Hornet::Shibe
  include Discord::Plugin

  SHIBE_URL = "http://shibe.online/api/shibes?count=100"
  @urls = [] of String

  def next_url
    if @urls.empty?
      @urls = fetch_urls
      next_url
    else
      @urls.shift
    end
  end

  def fetch_urls
    response = HTTP::Client.get(SHIBE_URL)
    Array(String).from_json(response.body)
  end

  @[Discord::Handler(event: :message_create)]
  def handle(payload, _ctx)
    url = next_url
    embed = Discord::Embed.new(title: "link", url: url,
      image: Discord::EmbedImage.new(url: url), colour: 0xc5be8a)
    client.create_message(payload.channel_id, "", embed)
  end
end
