require "./spec_helper"

module Hornet
  describe CaRCi do
    describe CaRCi::RunRequest do
      it "serializes" do
        request = CaRCi::RunRequest.new("foo", "bar", "baz")
        expected = %({"run_request":{"language":"foo","version":"bar","code":"baz"}})
        request.to_json.should eq expected
      end
    end

    describe CaRCi::Response do
      it "parses" do
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
        CaRCi::Response.from_json(json)
      end
    end

    describe CaRCi::Response::Sanitizer do
      it "cleans color codes from strings" do
        parser = JSON::PullParser.new %("[1m$global_variables are not supported, use @@class_variables instead[0m")
        result = CaRCi::Response::Sanitizer.from_json(parser)
        result.should eq "$global_variables are not supported, use @@class_variables instead"
      end
    end
  end
end
