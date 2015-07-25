require "tempfile"
require "yaml"

module BoshDeploymentResource
  class BoshManifest
    def initialize(path)
      @manifest = YAML.load_file(path)
    end

    def name
      manifest.fetch("name")
    end

    def use_release(release)
      manifest.fetch("releases").
        find { |r| r.fetch("name") == release.name }.
        store("version", release.version)
    end

    def use_stemcell(stemcell)
      manifest.fetch("resource_pools").
        find_all { |r| r.fetch("stemcell").fetch("name") == stemcell.name }.
        each { |r| r.fetch("stemcell").store("version", stemcell.version) }
    end

    def write!
      file = Tempfile.new("bosh_manifest")

      File.write(file.path, YAML.dump(manifest))

      file
    end

    private

    attr_reader :manifest
  end
end
