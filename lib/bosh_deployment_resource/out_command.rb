require 'time'

module BoshDeploymentResource
  class OutCommand
    def initialize(bosh, manifest, writer=STDOUT)
      @bosh = bosh
      @manifest = manifest
      @writer = writer
    end

    def run(working_dir, request)
      validate! request

      stemcells = []
      releases = []

      find_stemcells(working_dir, request).each do |stemcell_path|
        stemcell = BoshStemcell.new(stemcell_path)
        manifest.use_stemcell(stemcell)

        bosh.upload_stemcell(stemcell_path)

        stemcells << stemcell
      end

      find_releases(working_dir, request).each do |release_path|
        release = BoshRelease.new(release_path)
        manifest.use_release(release)

        bosh.upload_release(release_path)

        releases << release
      end

      new_manifest_path = manifest.write!
      bosh.deploy(new_manifest_path)

      time = bosh.last_deployment_time(manifest.name)
      response = {
        "version" => {
          "timestamp" => time.utc.iso8601
        },
        "metadata" =>
          stemcells.map { |s| { "name" => "stemcell", "value" => "#{s.name} v#{s.version}" } } +
          releases.map { |r| { "name" => "release", "value" => "#{r.name} v#{r.version}" } }
      }

      writer.puts response.to_json
    end

    private

    attr_reader :bosh, :manifest, :writer

    def validate!(request)
      ["target", "username", "password", "deployment"].each do |field|
        request.fetch("source").fetch(field) { raise "source must include '#{field}'" }
      end

      deployment_name = request.fetch("source").fetch("deployment")
      if manifest.name != deployment_name
        raise "given deployment name '#{deployment_name}' does not match manifest name '#{manifest.name}'"
      end

      ["manifest", "stemcells", "releases"].each do |field|
        request.fetch("params").fetch(field) { raise "params must include '#{field}'" }
      end

      raise "stemcells must be an array of globs" unless enumerable?(request.fetch("params").fetch("stemcells"))
      raise "releases must be an array of globs" unless enumerable?(request.fetch("params").fetch("releases"))
    end

    def find_stemcells(working_dir, request)
      globs = request.
        fetch("params").
        fetch("stemcells")

      glob(working_dir, globs)
    end

    def find_releases(working_dir, request)
      globs = request.
        fetch("params").
        fetch("releases")

      glob(working_dir, globs)
    end

    def glob(working_dir, globs)
      paths = []

      globs.each do |glob|
        abs_glob = File.join(working_dir, glob)
        results = Dir.glob(abs_glob)

        raise "glob '#{glob}' matched no files" if results.empty?

        paths.concat(results)
      end

      paths.uniq
    end

    def enumerable?(object)
      object.is_a? Enumerable
    end
  end
end
