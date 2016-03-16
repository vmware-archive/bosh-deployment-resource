require "json"

module BoshDeploymentResource
  class CheckCommand
    def initialize(bosh, writer=STDOUT)
      @bosh = bosh
      @writer = writer
    end

    def run(working_dir, request)
      deployment_name = request.fetch("source").fetch("deployment")
      manifest_path = File.join(working_dir, "manifest.yml")
      bosh.download_manifest(deployment_name, manifest_path)

      manifest_sha1 = Digest::SHA1.file(manifest_path).hexdigest
      writer.puts([{ "manifest_sha1" => manifest_sha1 }].to_json)
    end

    private

    attr_reader :writer, :bosh
  end
end
