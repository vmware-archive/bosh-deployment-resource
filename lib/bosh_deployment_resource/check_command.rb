require "json"

module BoshDeploymentResource
  class CheckCommand
    def initialize(bosh, writer=STDOUT)
      @bosh = bosh
      @writer = writer
    end

    def run(request)
      deployment_name = request.fetch("source").fetch("deployment")

      versions = []

      if bosh.target != ""
        Dir.mktmpdir do |working_dir|
          manifest_path = File.join(working_dir, "manifest.yml")
          bosh.download_manifest(deployment_name, manifest_path)
          manifest = BoshDeploymentResource::BoshManifest.new(manifest_path)
          manifest_sha = manifest.shasum

          existing_version = request.fetch("version")
          if existing_version == nil || manifest_sha != existing_version.fetch("manifest_sha1")
            versions << { "manifest_sha1" => manifest_sha }
          end
        end
      end

      writer.puts(versions.to_json)
    end

    private

    attr_reader :writer, :bosh
  end
end
