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
        find(no_release_found(release.name)) { |r| r.fetch("name") == release.name }.
        store("version", release.version)
    end

    def use_stemcell(stemcell)
      latest_stemcells.find_all { |s|
        s.fetch("version") == "latest" &&
          (s.has_key?("name") && s.fetch("name") == stemcell.name) ||
            (s.has_key?("os") && s.fetch("os") == stemcell.os)
      }.each { |s| s.store("version", stemcell.version) }
    end

    def fallback_director_uuid(new_uuid)
      manifest["director_uuid"] ||= new_uuid
    end

    def write!
      file = Tempfile.new("bosh_manifest")

      File.write(file.path, YAML.dump(manifest))

      file
    end

    def shasum
      sum = -> (o, digest) {
        case
        when o.respond_to?(:keys)
          o.sort.each do |k,v|
            digest << k.to_s
            sum[v, digest]
          end
        when o.respond_to?(:each)
          o.each { |x| sum[x, digest] }
        else
          digest << o.to_s
        end
      }

      d = Digest::SHA1.new
      sum[manifest, d]

      d.hexdigest
    end

    def validate_stemcells(stemcells)
      latest_stemcells.each do |manifest_stemcell|
        if manifest_stemcell.has_key?("name")
          matching_stemcells = stemcells.find_all { |s| s.name == manifest_stemcell.fetch("name") }
        elsif manifest_stemcell.has_key?("os")
          matching_stemcells = stemcells.find_all { |s| s.os == manifest_stemcell.fetch("os") }
        end

        if matching_stemcells.size > 1
          raise stemcell_validation_error_message(manifest_stemcell)
        end
      end
    end

    private

    attr_reader :manifest

    def stemcell_validation_error_message(manifest_stemcell)
      name = manifest_stemcell["alias"] || manifest_stemcell["name"]
      "Cannot update stemcell version in manifest for #{name} from 'latest', found multiple matching stemcells"
    end

    def no_release_found(name)
        Proc.new { raise "#{name} can not be found in manifest releases" }
    end

    def latest_stemcells
      if manifest.has_key?("stemcells")
        manifest.fetch("stemcells")
      else
        manifest.fetch("resource_pools").map { |rp| rp.fetch("stemcell") }
      end.find_all { |s| s.fetch("version") == "latest" }
    end
  end
end
