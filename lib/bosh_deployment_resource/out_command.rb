module BoshDeploymentResource
  class OutCommand
    def initialize(bosh)
      @bosh = bosh
    end

    def run(working_dir, request)
      validate! request

      stemcells(working_dir, request).each do |stemcell_path|
        bosh.upload_stemcell(stemcell_path)
      end

      releases(working_dir, request).each do |release_path|
        bosh.upload_release(release_path, rebase_releases?(request))
      end
    end

    private

    attr_reader :bosh

    def validate!(request)
      ["target", "username", "password"].each do |field|
        request.fetch("source").fetch(field) { raise "source must include '#{field}'" }
      end

      ["manifest", "stemcells", "releases"].each do |field|
        request.fetch("params").fetch(field) { raise "params must include '#{field}'" }
      end

      raise "stemcells must be an array of globs" unless enumerable?(request.fetch("params").fetch("stemcells"))
      raise "releases must be an array of globs" unless enumerable?(request.fetch("params").fetch("releases"))
    end

    def rebase_releases?(request)
      request.fetch("params").fetch("rebase", false)
    end

    def stemcells(working_dir, request)
      globs = request.
        fetch("params").
        fetch("stemcells")

      glob(working_dir, globs)
    end

    def releases(working_dir, request)
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
