require "json"
require "time"

module BoshDeploymentResource
  class InCommand
    def initialize(writer=STDOUT)
      @writer = writer
    end

    def run(working_dir, request)
      time = request
        .fetch("version", {})
        .fetch("timestamp", Time.now.utc.iso8601)

      response = {
        "version" => {
          "timestamp" => time
        }
      }

      writer.puts(response.to_json)
    end

    private

    attr_reader :writer
  end
end
