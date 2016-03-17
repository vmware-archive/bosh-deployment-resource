require "json"
require "time"

module BoshDeploymentResource
  class InCommand
    def initialize(bosh, writer=STDOUT)
      @writer = writer
      @bosh = bosh
    end

    def run(working_dir, request)
      raise "no version specified" unless request["version"]

      if bosh.target != ""
        deployment_name = request.fetch("source").fetch("deployment")
        bosh.download_manifest(deployment_name, File.join(working_dir, "manifest.yml"))

        File.open(File.join(working_dir, "target"), "w+") do |f|
          f << bosh.target
        end
      end

      writer.puts({
        "version" => request.fetch("version")
      }.to_json)
    end

    private

    attr_reader :writer, :bosh
  end
end
