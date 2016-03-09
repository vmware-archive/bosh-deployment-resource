module BoshDeploymentResource
  class CaCert
    def initialize(ca_cert_contents)
      @ca_cert_contents = ca_cert_contents
    end

    def provided?
      !@ca_cert_contents.nil?
    end

    def path
      return @file.path if @file

      @file = Tempfile.new("bosh_ca_cert")
      File.write(@file.path, @ca_cert_contents)

      @file.path
    end

    def cleanup
      @file.delete if @file
    end
  end
end

