require "../spec_helper"

describe Hornet::CommandParser do
  it "#parse" do
    expected = Hornet::CommandParser::ParsedCommand.new(
      [Hornet::CommandParser::Argument.new("1"),
       Hornet::CommandParser::Argument.new("2"),
       Hornet::CommandParser::Argument.new("quoted arg")],
      [Hornet::CommandParser::NamedArgument.new("named", Hornet::CommandParser::Argument.new("arg"))],
      [Hornet::CommandParser::Flag.new("flag")],
    )
    parsed = Hornet::CommandParser.parse(%(1 2 "quoted arg" --named=arg -flag))
    parsed.arguments.should eq expected.arguments
    parsed.named_arguments.should eq expected.named_arguments
    parsed.flags.should eq expected.flags
  end
end

private def cast(argument, method)
  case method
  when "to_i"
    argument.to_i
  when "to_f"
    argument.to_f
  when "to_bool"
    argument.to_bool
  when "to_snowflake"
    argument.to_snowflake
  when "codeblock"
    argument.codeblock
  else
    raise "Unknown method: #{method}"
  end
end

private def it_casts(method, raw, expected, error)
  it "casts #{raw.inspect} into #{expected.inspect} or raises #{error.inspect}" do
    argument = Hornet::CommandParser::Argument.new(raw)
    cast(argument, method).should eq expected

    argument = Hornet::CommandParser::Argument.new("")
    expect_raises(Hornet::CommandParser::Argument::Error, error) do
      cast(argument, method)
    end
  end
end

describe Hornet::CommandParser::Argument do
  it_casts("to_i", "1", 1, %("" is not a valid integer))
  it_casts("to_f", "1", 1.0, %("" is not a valid float))
  it_casts("to_bool", "true", true, %("" is not a valid bool (true/false, yes/no)))
  it_casts("to_bool", "false", false, %("" is not a valid bool (true/false, yes/no)))
  it_casts("to_snowflake", "1", Discord::Snowflake.new(1), %("" is not a valid snowflake))

  it_casts("codeblock", <<-END, Hornet::CommandParser::CodeBlock.new("cr", "content"), "could not find a valid code block in your message")
  outer content
  ```cr
  content
  ```
  outer content
  END

  # TODO: lang-less code blocks
  # it_casts("codeblock", <<-END, Hornet::CommandParser::CodeBlock.new("", ""), "could not find a valid code block in your message")
  # outer content
  # ```
  # ```
  # outer content
  # END
end

describe Hornet::CommandParser::ParsedCommand do
  it "finds flags" do
    parsed = Hornet::CommandParser.parse("-foo")
    parsed.flag("foo").should be_true
    parsed.flag("bar").should be_false
  end

  it "finds named arguments" do
    parsed = Hornet::CommandParser.parse("--foo=bar")
    parsed.named_argument?("foo").should be_a Hornet::CommandParser::Argument
    parsed.named_argument?("bar").should be_nil
  end
end

class FlipperCommand
  def initialize(@parsed : Hornet::CommandParser::ParsedCommand)
  end
end
