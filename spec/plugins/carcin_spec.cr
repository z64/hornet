require "../spec_helper"

@[Discord::Plugin::Options(client_class: MockClient, middleware: true)]
class Hornet::CARCIN
  include Discord::Plugin

  property! loaded_response : Response

  struct Response
    setter stderr
    setter stdout
    setter exit_code
  end

  def execute(run_request : RunRequest)
    loaded_response
  end
end

describe Hornet::CARCIN::RunRequest do
  it "#to_json" do
    request = Hornet::CARCIN::RunRequest.new("language", "version", "code")
    request.to_pretty_json.should eq <<-JSON
    {
      "run_request": {
        "language": "language",
        "version": "version",
        "code": "code"
      }
    }
    JSON
  end
end

describe Hornet::CARCIN::Response do
  it ".from_json" do
    json = <<-JSON
      {
        "run_request": {
           "run": {
              "code": "code",
              "created_at": "2018-02-08T23:22:49Z",
              "download_url": "url",
              "exit_code": 0,
              "html_url": "url",
              "id": "id",
              "language": "language",
              "stderr": "stderr",
              "stdout": "stdout",
              "url": "url",
              "version": "version"
          }
        }
      }
      JSON
    Hornet::CARCIN::Response.from_json(json)
  end

  it "raises on invalid inner object" do
    json = %({"foo": "bar"})
    expect_raises(Exception, "Failed to parse response: #{json}") do
      Hornet::CARCIN::Response.from_json(json)
    end
  end
end

describe Hornet::CARCIN do
  plugin = Hornet::CARCIN.new
  client = MockClient.new
  plugin.register_on(client)

  it "#parse_request" do
    valid_request = <<-MESSAGE
      ```cr
      foo
      ```
      MESSAGE
    plugin.parse_request?(valid_request).should eq({Hornet::CARCIN::LANGS["cr"], "foo\n"})

    unknown_lang = <<-MESSAGE
      ```lua
      foo
      ```
      MESSAGE
    plugin.parse_request?(unknown_lang).should eq({"lua", "foo\n"})

    invalid_request = "foo"
    plugin.parse_request?(invalid_request).should eq(nil)
  end

  example_response = Hornet::CARCIN::Response.new(
    id: "id",
    code: "code",
    created_at: Time.now,
    download_url: "download url",
    exit_code: 0,
    html_url: "html url",
    language: "language",
    stderr: "",
    stdout: "",
    url: "carcin url",
    version: "version")

  it "processes succesful request (STDOUT)" do
    command = MessageStub.new(1, <<-MESSAGE)
      ```cr
      puts "hello world"
      ```
      MESSAGE

    response = example_response.dup
    response.stdout = "stdout"
    response.exit_code = 0
    plugin.loaded_response = response
    result = plugin.handle(command, :ctx)

    expected_embed = Discord::Embed.new(
      title: "View on carc.in",
      url: "html url",
      footer: Discord::EmbedFooter.new(text: "language version (exit code 0)"))
    expected = MessageStub.new(1, <<-MESSAGE, expected_embed)
      ```
      stdout
      ```
      MESSAGE
    result.should eq expected
  end

  it "processes succesful request (STDERR)" do
    command = MessageStub.new(1, <<-MESSAGE)
      ```cr
      puts "hello world"
      ```
      MESSAGE

    response = example_response.dup
    response.stderr = "stderr"
    response.exit_code = 1
    plugin.loaded_response = response
    result = plugin.handle(command, :ctx)

    expected_embed = Discord::Embed.new(
      title: "View on carc.in",
      url: "html url",
      footer: Discord::EmbedFooter.new(text: "language version (exit code 1)"))
    expected = MessageStub.new(1, <<-MESSAGE, expected_embed)
      ```
      stderr
      ```
      MESSAGE
    result.should eq expected
  end

  it "processes succesful request (STDOUT and STDERR)" do
    command = MessageStub.new(1, <<-MESSAGE)
      ```cr
      puts "hello world"
      ```
      MESSAGE

    response = example_response.dup
    response.stderr = "stderr"
    response.stdout = "stdout"
    response.exit_code = 1
    plugin.loaded_response = response
    result = plugin.handle(command, :ctx)

    expected_embed = Discord::Embed.new(
      title: "View on carc.in",
      url: "html url",
      footer: Discord::EmbedFooter.new(text: "language version (exit code 1)"))
    expected = MessageStub.new(1, <<-MESSAGE, expected_embed)
      **stdout**
      ```
      stdout
      ```
      **stderr**
      ```
      stderr
      ```
      MESSAGE
    result.should eq expected
  end

  it "doesn't process unknown language" do
    command = MessageStub.new(1, <<-MESSAGE)
      ```lol
      HAI
      CAN HAS STDIO?
      VISIBLE "HAI WORLD!"
      KTHXBYE
      ```
      MESSAGE
    response = plugin.handle(command, :ctx)
    expected = MessageStub.new(1, "unsupported language: `lol`")
    response.should eq expected
  end

  it "doesn't process bad format" do
    command = MessageStub.new(1, "foo")
    response = plugin.handle(command, :ctx)
    expected = MessageStub.new(1, "invalid syntax, must match: `#{Hornet::CARCIN::CODE_BLOCK}`")
    response.should eq expected
  end
end
