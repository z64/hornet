struct Hornet::CommandParser
  struct Argument
    class Error < Exception
      def initialize(@reason : String)
        super
      end

      def message
        @reason
      end
    end

    def initialize(@raw : String)
    end

    def to_s
      @raw
    end

    def to_i
      to_i? || raise Error.new(%("#{@raw}" is not a valid integer))
    end

    def to_i?
      @raw.to_i?
    end

    def to_f
      to_f? || raise Error.new(%("#{@raw}" is not a valid float))
    end

    def to_f?
      @raw.to_f?
    end

    def to_bool
      value = to_bool?
      raise Error.new(%("#{@raw}" is not a valid bool (true/false, yes/no))) if value.nil?
      value
    end

    def to_bool?
      case @raw
      when "true", "yes", "yep", "yeet", "y", "t", "on", "enable"
        true
      when "false", "no", "nope", "yeetn't", "n", "f", "off", "disable"
        false
      else
        nil
      end
    end

    def to_snowflake
      to_snowflake? || raise Error.new(%("#{@raw}" is not a valid snowflake))
    end

    def to_snowflake?
      if value = @raw.to_u64?
        Discord::Snowflake.new(value)
      else
        nil
      end
    end

    def codeblock
      codeblock? || raise Error.new("could not find a valid code block in your message")
    end

    def codeblock?
      CodeBlock.extract?(@raw)
    end
  end

  record CodeBlock, language : String?, content : String do
    CODE_BLOCK_REGEXP = /```([a-zA-Z]+)\n([\s\S]+?)```/i

    def self.extract?(string : String)
      if match = CODE_BLOCK_REGEXP.match(string)
        CodeBlock.new(match[1].strip, match[2].strip)
      end
    end
  end

  struct NamedArgument
    getter name : String
    getter value : Argument

    def initialize(@name : String, @value : Argument)
    end
  end

  struct Flag
    getter name : String

    def initialize(@name : String)
    end
  end

  class ParsedCommand
    class Error < Exception
      def initialize(@reason : String)
        super
      end

      def message
        @reason
      end
    end

    getter arguments : Array(Argument)
    getter named_arguments : Array(NamedArgument)
    getter flags : Array(Flag)

    def initialize(@arguments : Array(Argument), @named_arguments : Array(NamedArgument),
                   @flags : Array(Flag))
    end

    def [](index : Int32)
      @arguments[index]? || raise Error.new("insufficient arguments")
    end

    def flag(name : String)
      @flags.any? { |f| f.name == name }
    end

    def named_argument?(name : String)
      @named_arguments.find { |arg| arg.name == name }.try(&.value)
    end
  end

  def self.parse(string : String)
    arguments = Array(Argument).new
    named_arguments = Array(NamedArgument).new
    flags = Array(Flag).new

    new(string).parse do |parsed|
      case parsed
      when Argument
        arguments << parsed
      when NamedArgument
        named_arguments << parsed
      when Flag
        flags << parsed
      end
    end

    ParsedCommand.new(arguments, named_arguments, flags)
  end

  def initialize(string : String)
    @reader = Char::Reader.new(string)
  end

  def parse
    while @reader.has_next?
      case @reader.current_char
      when '-'
        @reader.next_char
        if @reader.current_char == '-'
          @reader.next_char
          name, _, value = read_argument.partition('=')
          value = Argument.new(value)
          yield NamedArgument.new(name, value)
        else
          name = read_argument
          yield Flag.new(name)
        end
      when ' '
        @reader.next_char
      else
        value = read_argument
        yield Argument.new(value)
      end
    end
  end

  private def read_argument
    quoted = false
    String.build do |string|
      while true
        case @reader.current_char
        when ' '
          if quoted
            string << ' '
            @reader.next_char
          else
            break
          end
        when '"'
          @reader.next_char
          if quoted
            break
          else
            quoted = true
          end
        else
          break unless @reader.has_next?
          string << @reader.current_char
          @reader.next_char
        end
      end
    end
  end
end
