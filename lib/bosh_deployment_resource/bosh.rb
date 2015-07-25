require "json"
require "pty"

module BoshDeploymentResource
  class Bosh
    def initialize(target, username, password, command_runner=CommandRunner.new)
      @target = target
      @username = username
      @password = password
      @command_runner = command_runner
    end

    def upload_stemcell(path)
      bosh("upload stemcell #{path} --skip-if-exists")
    end

    def upload_release(path)
      bosh("upload release #{path} --skip-if-exists")
    end

    def deploy(manifest_path)
      bosh("-d #{manifest_path} deploy")
    end

    private

    attr_reader :target, :username, :password, :command_runner

    def bosh(command)
      run(
        "bosh -n --color -t #{target} #{command}",
        "BOSH_USER" => username,
        "BOSH_PASSWORD" => password,
      )
    end

    def run(command, env={})
      command_runner.run(command, env)
    end
  end

  class CommandRunner
    def run(command, env={})
      pid = Process.spawn(env, command, out: :err, err: :err)
      Process.wait(pid)
      raise "command '#{command}' failed!" unless $?.success?
    end
  end
end
