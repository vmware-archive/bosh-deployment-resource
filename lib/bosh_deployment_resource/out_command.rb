require 'digest'
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

      bosh.cleanup if request.fetch("params")["cleanup"].equal? true

      stemcells = []
      releases = []

      manifest.fallback_director_uuid(bosh.director_uuid)

      stemcells = find_stemcells(working_dir, request).map do |stemcell_path|
        BoshStemcell.new(stemcell_path)
      end

      manifest.validate_stemcells(stemcells)

      stemcells.each do |stemcell|
        manifest.use_stemcell(stemcell)
        bosh.upload_stemcell(stemcell.path)
      end

      find_releases(working_dir, request).each do |release_path|
        release = BoshRelease.new(release_path)
        manifest.use_release(release)

        bosh.upload_release(release_path)

        releases << release
      end

      new_manifest = manifest.write!

      bosh.deploy(new_manifest.path)

      response = {
        "version" => {
          "manifest_sha1" => manifest.shasum,
          "target" => bosh.target
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
      request.fetch("source").fetch("deployment") { raise "source must include 'deployment'" }

      deployment_name = request.fetch("source").fetch("deployment")
      if manifest.name != deployment_name
        raise "given deployment name '#{deployment_name}' does not match manifest name '#{manifest.name}'"
      end

      case request.fetch("params")["cleanup"]
      when nil, true, false
      else
        raise "given cleanup value must be a boolean"
      end

      ["manifest", "stemcells"].each do |field|
        request.fetch("params").fetch(field) { raise "params must include '#{field}'" }
      end


      request.fetch("params").fetch("releases") {
        request.fetch("params").fetch("tiles") {
          raise "params must include either releases or tiles"
        }
      }

      raise "stemcells must be an array of globs" unless enumerable?(request.fetch("params").fetch("stemcells"))
      raise "either releases or tiles must be an array of globs" unless
        enumerable?(request.fetch("params").fetch("releases", nil)) ||
        enumerable?(request.fetch("params").fetch("tiles", nil))
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
        fetch("releases", [])

      release_paths = glob(working_dir, globs)

      release_paths.concat(find_and_unpack_tiles(working_dir, request))
      release_paths
    end

    def find_and_unpack_tiles(working_dir, request)
      globs = request.
        fetch("params").
        fetch("tiles",[])

      tile_paths = glob(working_dir, globs)
      release_paths = []
      tile_paths.each do |tile_path|
        unpacked_tile_dir = Dir.mktmpdir("unpacked_tile_")
        unzip_output = `unzip #{tile_path} -d #{unpacked_tile_dir} releases/*`
        unzip_status = $?.to_i
        raise "UNZIP FAILED. TROLOLOLOLOL: #{unzip_output}\n #{unzip_status}" unless unzip_status == 0
        release_paths.concat glob(unpacked_tile_dir, ["releases/*.tgz"])
      end

      release_paths
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
