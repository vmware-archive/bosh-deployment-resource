require "json"
require "open3"

require "faraday"

module BoshDeploymentResource
  class Bosh
    def initialize(target, username, password, ignore_ssl)
      @target = target
      @username = username
      @password = password
      @ignore_ssl = ignore_ssl
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

    def last_deployment_time(deployment_name)
      response = http_client.get "/tasks", { "state" => "done" }
      tasks = JSON.parse(response.body)

      latest_task = tasks.
        select { |t| t.fetch("result") == "/deployments/#{deployment_name}" }.
        first

      Time.at(latest_task.fetch("timestamp")) if latest_task
    end

    private

    attr_reader :target, :username, :password, :ignore_ssl

    def http_client
      @http_client ||= begin
        conn = Faraday.new(url: target, ssl: { verify: !ignore_ssl })
        conn.basic_auth username, password
        conn
      end
    end

    def bosh(command)
      run("bosh -n -t #{target} -u #{username} -p #{password} #{command}")
    end

    def run(command)
      pid = Process.spawn(command, out: :err, err: :err)
      Process.wait(pid)

      raise "command '#{command} failed!" unless $?.success?
    end
  end
end
