require "open3"
require "yaml"
require "zlib"

require "archive/tar/minitar"

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
      tgz = Zlib::GzipReader.new(File.open(path, 'rb'))
      reader = Archive::Tar::Minitar::Reader.open(tgz)

      reader.each_entry do |entry|
        next unless File.basename(entry.full_name) == "release.MF"

        return entry.read
      end

      raise "could not find release.MF"
    end

    attr_reader :path
  end
end
