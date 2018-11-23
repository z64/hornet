@[Discord::Plugin::Options(middleware: {DiscordMiddleware::Error.new("error: `%exception%`"),
                                        DiscordMiddleware::Prefix.new("<@#{Hornet::CLIENT_ID}> eval"),
                                        Hornet::Flipper.new("carcin")})]
class Hornet::CARCIN
  include Discord::Plugin

  @[Discord::Handler(event: :message_create)]
  def handle(payload, _ctx)
    if parsed = parse_request?(payload.content)
      lang, code = parsed

      if lang.is_a?(String)
        reply = client.create_message(
          payload.channel_id,
          "unsupported language: `#{lang}`")
        return reply
      end

      client.trigger_typing_indicator(payload.channel_id)
      response = execute(RunRequest.new(lang[0], lang[1], code))
      footer = Discord::EmbedFooter.new(text: "#{response.language} #{response.version} (exit code #{response.exit_code})")
      embed = Discord::Embed.new(title: "View on carc.in", url: response.html_url, footer: footer)

      stdout = !response.stdout.empty?
      stderr = !response.stderr.empty?

      content = String.build do |string|
        string << "**stdout**\n" if stdout && stderr

        if stdout
          string << "```\n"
          string << response.stdout
          string << "\n```"
          string << '\n' if stderr
        end

        string << "**stderr**\n" if stdout && stderr

        if stderr
          string << "```\n"
          string << response.stderr
          string << "\n```"
        end
      end

      if content.size < 2000
        client.create_message(payload.channel_id, content, embed)
      else
        client.create_message(payload.channel_id, "message too long (#{content.size} / 2000)")
      end
    else
      client.create_message(
        payload.channel_id,
        "invalid syntax, must match: `#{CODE_BLOCK}`")
    end
  end

  def parse_request?(content : String)
    if match = CODE_BLOCK.match(content)
      _, requested_lang, code = match
      {LANGS[requested_lang]? || requested_lang, code}
    end
  end

  def execute(run_request : RunRequest)
    response = HTTP::Client.post("#{CARCIN_URL}/run_requests", CARCIN_HEADERS, run_request.to_json)
    raise "Request to carc.in failed:\n```\n#{response.inspect}\n```" unless response.success?
    Response.from_json(response.body)
  end

  CARCIN_URL = "https://carc.in"

  CODE_BLOCK = /```([a-zA-Z]+)\n([\s\S]+?)```/i

  CARCIN_HEADERS = HTTP::Headers{
    "Accept"           => "application/json",
    "Content-Type"     => "application/json; charset=utf-8",
    "User-Agent"       => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Safari/537.36",
    "Referer"          => "https://carc.in",
    "X-Requested-With" => "XMLHttpRequest",
  }

  LANGS = {
    "crystal" => {"crystal", "0.27.0"},
    "cr"      => {"crystal", "0.27.0"},
    "ruby"    => {"ruby", "2.4.1"},
    "rb"      => {"ruby", "2.4.1"},
    "c"       => {"gcc", "6.3.1"},
  }

  record Language, id : String, name : String, versions : Array(String) do
    include JSON::Serializable
  end

  record RunRequest, language : String, version : String, code : String do
    include JSON::Serializable

    def to_json(builder : JSON::Builder)
      builder.object do
        builder.field("run_request") do
          builder.object do
            builder.field("language", language)
            builder.field("version", version)
            builder.field("code", code)
          end
        end
      end
    end
  end

  struct Response
    include JSON::Serializable

    module Sanitizer
      def self.from_json(parser : JSON::PullParser)
        str = parser.read_string
        str.gsub(/\e?\[(\d+)m/, "")
      end
    end

    getter id : String
    getter code : String
    getter created_at : Time
    getter download_url : String
    getter exit_code : Int32
    getter html_url : String
    getter language : String

    @[JSON::Field(converter: Hornet::CARCIN::Response::Sanitizer)]
    getter stderr : String

    @[JSON::Field(converter: Hornet::CARCIN::Response::Sanitizer)]
    getter stdout : String

    getter url : String
    getter version : String

    def self.from_json(string_or_io : String | IO)
      parser = JSON::PullParser.new(string_or_io)
      parser.on_key("run_request") do
        parser.on_key("run") do
          return new(parser)
        end
      end
      raise "Failed to parse response: #{string_or_io.to_s}"
    end

    def initialize(@id : String, @code : String, @created_at : Time,
                   @download_url : String, @exit_code : Int32,
                   @html_url : String, @language : String, @stderr : String,
                   @stdout : String, @url : String, @version : String)
    end
  end
end
