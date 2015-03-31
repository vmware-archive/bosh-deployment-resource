require "open3"
require "yaml"

module BoshDeploymentResource
  class BoshRelease
    def initialize(path)
      @path = path
    end

    def name
      manifest.fetch("name")
    end

    def version
      manifest.fetch("version")
    end

    private

    def manifest
      @manifest ||= YAML.load(manifest_file_contents)
    end

    def manifest_file_contents
      stdout, _ = Open3.capture2("tar -O --extract --file #{path} release.MF")
      stdout
    end

    attr_reader :path
  end
end
