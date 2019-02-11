class Hornet::CommandSpec
  def initialize(@name : String, @usage : String, @min_args : Int32? = nil, @max_args : Int32? = nil)
  end

  PREFIXES = {
    "<@#{Hornet::CLIENT_ID}>",
    "<@!#{Hornet::CLIENT_ID}>",
    "h>",
  }

  def call(payload, ctx)
    prefix, name, args = payload.content.partition(@name)
    return unless PREFIXES.includes?(prefix.strip) && name == @name

    client = ctx[Discord::Client]
    parsed = Hornet::CommandParser.parse(args)

    if min_args = @min_args
      if parsed.arguments.size < min_args
        return client.create_message(payload.channel_id, <<-MESSAGE)
        `<error>` too few arguments (#{parsed.arguments.size} given, minimum: #{min_args})
        `<usage>` #{@usage}
        MESSAGE
      end
    end

    if max_args = @max_args
      if parsed.arguments.size > max_args
        return client.create_message(payload.channel_id, <<-MESSAGE)
        `<error>` too many arguments (#{parsed.arguments.size} given, maximum: #{max_args})
        `<usage>` #{@usage}
        MESSAGE
      end
    end

    ctx.put(parsed)

    begin
      yield
    rescue err : Hornet::CommandParser::Argument::Error | Hornet::CommandParser::ParsedCommand::Error
      client.create_message(payload.channel_id, <<-MESSAGE)
      `<error>` #{err.message}
      `<usage>` #{@usage}
      MESSAGE
    end
  end
end
