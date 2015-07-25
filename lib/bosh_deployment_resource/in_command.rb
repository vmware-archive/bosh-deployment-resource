require "json"
require "time"

module BoshDeploymentResource
  class InCommand
    def initialize(writer=STDOUT)
      @writer = writer
    end

    def run(working_dir, request)
      raise "no version specified" unless request["version"]

      writer.puts({
        "version" => request.fetch("version")
      }.to_json)
    end

    private

    attr_reader :writer
  end
end
