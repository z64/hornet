module Hornet
  module CaRCi
    CARCIN_URL = "https://carc.in"

    struct Language
      JSON.mapping(id: String, name: String, versions: Array(String))
    end

    struct RunRequest
      JSON.mapping(language: String, version: String, code: String)

      def initialize(@language : String, @version : String, @code : String)
      end

      def to_json(builder : JSON::Builder)
        builder.object do
          builder.field("run_request") do
            previous_def(builder)
          end
        end
      end
    end

    struct Response
      JSON.mapping(
        id: String,
        code: String,
        created_at: {type: Time, converter: Time::Format::ISO_8601_DATE_TIME},
        download_url: String,
        exit_code: Int32,
        html_url: String,
        language: String,
        stderr: String,
        stdout: String,
        url: String,
        version: String
      )

      def initialize(parser : JSON::PullParser)
        parser.on_key("run_request") do
          parser.on_key("run") do
            return previous_def(parser)
          end
        end
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
    "crystal" => {"crystal", "0.24.1"},
    "cr"      => {"crystal", "0.24.1"},
    "ruby"    => {"ruby", "2.4.1"},
    "rb"      => {"ruby", "2.4.1"},
    "c"       => {"gcc", "6.3.1"},
  }

  client.stack(:carcin_langs,
    DiscordMiddleware::Prefix.new("<@213450769276338177> carcin langs"),
    DiscordMiddleware::Error.new("error: %exception%"),
    Flipper.new("carcin")) do |ctx|
    client.trigger_typing_indicator(ctx.message.channel_id)

    languages = CaRCi.languages
    reply = String.build do |str|
      languages.each do |lang|
        # str.puts "**#{lang.name}:** (#{lang.id}) #{lang.versions.join(", ")}"
        str.puts "**#{lang.name}:** (#{lang.id}) #{lang.versions.first}"
      end
    end

    client.create_message(
      ctx.message.channel_id,
      reply)
  end

  client.stack(:carcin_run,
    DiscordMiddleware::Prefix.new("<@213450769276338177> eval"),
    DiscordMiddleware::Error.new("error: %exception%"),
    Flipper.new("carcin")) do |ctx|
    if match = CODE_BLOCK.match(ctx.message.content)
      _, requested_lang, code = match

      if lang = LANGS[requested_lang]?
        client.trigger_typing_indicator(ctx.message.channel_id)

        response = CaRCi.run(lang[0], lang[1], code)
        results = if response.stderr.empty? && response.exit_code.zero?
                    response.stdout
                  else
                    response.stderr
                  end
        content = "```#{requested_lang}\n#{results}\n```"
        content = "(output too long)" if content.size > 2000
        embed = Discord::Embed.new(
          title: "View on carc.in",
          url: response.html_url,
          description: "#{response.language} v#{response.version} (exit code #{response.exit_code})")
        client.create_message(
          ctx.message.channel_id,
          content,
          embed)
      else
        client.create_message(
          ctx.message.channel_id,
          "unsupported language: `#{requested_lang}`")
      end
    else
      client.create_message(
        ctx.message.channel_id,
        "invalid syntax, must match: `#{CODE_BLOCK.inspect}`")
    end
  end
end
