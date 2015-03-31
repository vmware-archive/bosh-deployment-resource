require "open3"

module BoshDeploymentResource
  class Bosh
    def initialize(target, username, password)
      @target = target
      @username = username
      @password = password
    end

    def upload_stemcell(path)
      bosh("upload stemcell #{path} --skip-if-exists")
    end

    def upload_release(path, rebase=false)
      command = "upload release #{path} --skip-if-exists"
      command << " --rebase" if rebase

      bosh(command)
    end

    def deploy(manifest_path)
      bosh("-d #{manifest_path} deploy")
    end

    private

    attr_reader :target, :username, :password

    def bosh(command)
      run("bosh -n -t #{target} -u #{username} -p #{password} #{command}")
    end

    def run(command)
      pid = Process.spawn(command, out: :out, err: :err)
      Process.wait(pid)

      raise "command '#{command} failed!" unless $?.success?
    end
  end
end
