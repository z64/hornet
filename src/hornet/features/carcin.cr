module Hornet
  module CaRCi
    CARCIN_URL = "https://carc.in"

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

      @[JSON::Field(converter: Hornet::CaRCi::Response::Sanitizer)]
      getter stderr : String

      @[JSON::Field(converter: Hornet::CaRCi::Response::Sanitizer)]
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
        raise "Failed to parse response: #{string_or_io}"
      end
    end

    def self.languages
      response = HTTP::Client.get(
        "#{CARCIN_URL}/languages",
        HTTP::Headers{
          "Accept"     => "application/json",
          "User-Agent" => "Hornet",
        })
      Array(Language).from_json(response.body, "languages")
    end

    def self.run(language : String, version : String, code : String)
      request = RunRequest.new(language, version, code)
      response = HTTP::Client.post(
        "#{CARCIN_URL}/run_requests",
        HTTP::Headers{
          "Accept"           => "application/json",
          "Accept-Encoding"  => "gzip, deflate, br",
          "Connection"       => "keep-alive",
          "Content-Type"     => "application/json; charset=utf-8",
          "User-Agent"       => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Safari/537.36",
          "Host"             => "carc.in",
          "Referer"          => "https://carc.in",
          "X-Requested-With" => "XMLHttpRequest",
        },
        request.to_json)
      raise "request to carc.in failed:\n```\n#{response.inspect}\n```" unless response.success?
      Response.from_json(response.body)
    end
  end

  CODE_BLOCK = /```([a-zA-Z]+)\n([\s\S]+?)```/i

  LANGS = {
    "crystal" => {"crystal", "0.25.0"},
    "cr"      => {"crystal", "0.25.0"},
    "ruby"    => {"ruby", "2.4.1"},
    "rb"      => {"ruby", "2.4.1"},
    "c"       => {"gcc", "6.3.1"},
  }

  client.on_message_create(
    DiscordMiddleware::Prefix.new("<@213450769276338177> carcin langs"),
    DiscordMiddleware::Error.new("error: %exception%"),
    Flipper.new("carcin")) do |payload, ctx|
    client.trigger_typing_indicator(payload.channel_id)

    languages = CaRCi.languages
    reply = String.build do |str|
      languages.each do |lang|
        # str.puts "**#{lang.name}:** (#{lang.id}) #{lang.versions.join(", ")}"
        str.puts "**#{lang.name}:** (#{lang.id}) #{lang.versions.first}"
      end
    end

    client.create_message(
      payload.channel_id,
      reply)
  end

  client.on_message_create(
    DiscordMiddleware::Prefix.new("<@213450769276338177> eval"),
    DiscordMiddleware::Error.new("error: %exception%"),
    Flipper.new("carcin")) do |payload, ctx|
    if match = CODE_BLOCK.match(payload.content)
      _, requested_lang, code = match

      if lang = LANGS[requested_lang]?
        client.trigger_typing_indicator(payload.channel_id)

        response = CaRCi.run(lang[0], lang[1], code)
        results = if response.stderr.empty? && response.exit_code.zero?
                    response.stdout
                  else
                    response.stderr
                  end
        content = "```\n#{results}\n```"
        content = "(output too long)" if content.size > 2000
        embed = Discord::Embed.new(
          title: "View on carc.in",
          url: response.html_url,
          description: "#{response.language} v#{response.version} (exit code #{response.exit_code})")
        client.create_message(
          payload.channel_id,
          content,
          embed)
      else
        client.create_message(
          payload.channel_id,
          "unsupported language: `#{requested_lang}`")
      end
    else
      client.create_message(
        payload.channel_id,
        "invalid syntax, must match: `#{CODE_BLOCK.inspect}`")
    end
  end
end
