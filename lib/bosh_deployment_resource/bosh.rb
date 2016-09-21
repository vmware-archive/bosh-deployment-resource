require "json"
require "pty"

module BoshDeploymentResource
  class Bosh
    attr_reader :target

    def initialize(target, ca_cert, auth, command_runner=CommandRunner.new)
      @target = target
      @ca_cert = ca_cert
      @auth = auth
      @command_runner = command_runner
      @no_redact = false
    end

    def enable_redact()
      @no_redact = true
    end
    
    def disable_redact()
      @disable_redact = false
    end

    def upload_stemcell(path)
      bosh("upload stemcell #{path} --skip-if-exists")
    end

    def upload_release(path)
      bosh("upload release #{path} --skip-if-exists")
    end

    def deploy(manifest_path)
      if @no_redact
          bosh("-d #{manifest_path} deploy --no-redact")
      else
          bosh("-d #{manifest_path} deploy")
      end
    end

    def download_manifest(deployment_name, manifest_path)
      bosh("download manifest #{deployment_name} #{manifest_path}")
    end

    def cleanup
      bosh("cleanup")
    end

    def director_uuid
      r, w = IO.pipe
      bosh("status --uuid", out: w)
      r.gets.strip
    ensure
      r.close
      w.close
    end

    private

    attr_reader :command_runner

    def bosh(command, opts={})
      args = ["-n", "--color", "-t", target]
      args << ["--ca-cert", @ca_cert.path] if @ca_cert.provided?
      run(
        "bosh #{args.join(" ")} #{command}",
        @auth.env,
        opts,
      )
    end

    def run(command, env={}, opts={})
      command_runner.run(command, env, opts)
    end
  end

  class CommandRunner
    def run(command, env={}, opts={})
      pid = Process.spawn(env, command, { out: :err, err: :err }.merge(opts))
      Process.wait(pid)
      raise "command '#{command}' failed!" unless $?.success?
    end
  end
end
