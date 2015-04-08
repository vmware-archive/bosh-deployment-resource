require "spec_helper"

response = <<-EOS
[
  {
    "id": 54,
    "state": "error",
    "description": "create deployment",
    "timestamp": 1427905795,
    "result": "(<unknown>): mapping values are not allowed in this context at line 1 column 32",
    "user": "admin"
  },
  {
    "id": 50,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1427733902,
    "result": "/deployments/concourse-testflight",
    "user": "admin"
  },
  {
    "id": 48,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1427733792,
    "result": "/deployments/garden-testflight",
    "user": "admin"
  },
  {
    "id": 45,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1427733727,
    "result": "/deployments/concourse-testflight",
    "user": "admin"
  },
  {
    "id": 40,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1427137404,
    "result": "/deployments/concourse",
    "user": "admin"
  },
  {
    "id": 39,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1427135263,
    "result": "/deployments/concourse",
    "user": "admin"
  },
  {
    "id": 36,
    "state": "error",
    "description": "create deployment",
    "timestamp": 1427134960,
    "result": "`worker/0' is not running after update",
    "user": "admin"
  },
  {
    "id": 34,
    "state": "error",
    "description": "create deployment",
    "timestamp": 1427134795,
    "result": "Action Failed get_task: Task 0510178d-6d79-493c-5070-379030c425c1 result: Compiling package blackbox: Running packaging script:...",
    "user": "admin"
  },
  {
    "id": 33,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1427134322,
    "result": "/deployments/concourse",
    "user": "admin"
  },
  {
    "id": 31,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1426812960,
    "result": "/deployments/garden-testflight",
    "user": "admin"
  },
  {
    "id": 27,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1426544576,
    "result": "/deployments/garden-testflight",
    "user": "admin"
  },
  {
    "id": 25,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1426542811,
    "result": "/deployments/garden-testflight",
    "user": "admin"
  },
  {
    "id": 22,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1426542595,
    "result": "/deployments/concourse-testflight",
    "user": "admin"
  },
  {
    "id": 21,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1426542530,
    "result": "/deployments/garden-testflight",
    "user": "admin"
  },
  {
    "id": 18,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1426542397,
    "result": "/deployments/concourse-testflight",
    "user": "admin"
  },
  {
    "id": 17,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1426542339,
    "result": "/deployments/garden-testflight",
    "user": "admin"
  },
  {
    "id": 14,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1426541975,
    "result": "/deployments/concourse-testflight",
    "user": "admin"
  },
  {
    "id": 13,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1426541913,
    "result": "/deployments/garden-testflight",
    "user": "admin"
  },
  {
    "id": 11,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1426541856,
    "result": "/deployments/concourse-testflight",
    "user": "admin"
  },
  {
    "id": 6,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1426540834,
    "result": "/deployments/garden-testflight",
    "user": "admin"
  },
  {
    "id": 4,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1426540775,
    "result": "/deployments/concourse-testflight",
    "user": "admin"
  }
]
EOS


describe BoshDeploymentResource::CommandRunner do
  let (:command_runner) { BoshDeploymentResource::CommandRunner.new }

  describe '.run' do
    it 'takes a command and an environment and spanws a process' do
      expect {
        command_runner.run('sh -c "$PROG"', "PROG" => "true")
      }.to_not raise_error
    end

    it 'raises an exception if the command fails' do
      expect {
        command_runner.run('sh -c "$PROG"', "PROG" => "false")
      }.to raise_error
    end

    it 'routes all output to stderr' do
      pid = 7223
      expect($?).to receive(:success?).and_return(true)
      expect(Process).to receive(:wait).with(pid)
      expect(Process).to receive(:spawn).with({}, 'echo "hello"', out: :err, err: :err).and_return(pid)

      command_runner.run('echo "hello"')
    end
  end
end

describe BoshDeploymentResource::Bosh do
  let(:target) { "http://bosh.example.com" }
  let(:username) { "bosh-userΩΩΩΩ" }
  let(:password) { "bosh-password!#%&#(*" }
  let(:command_runner) { instance_double(BoshDeploymentResource::CommandRunner) }

  let(:bosh) { BoshDeploymentResource::Bosh.new(target, username, password, false, command_runner) }

  before(:all) do
    WebMock.disable_net_connect!
  end

  after(:all) do
    WebMock.allow_net_connect!
  end

  describe ".uploading a stemcell" do
    it "runs the command to upload a stemcell" do
      expect(command_runner).to receive(:run).with(%{bosh -n --color -t #{target} upload stemcell /path/to/a/stemcell.tgz --skip-if-exists}, { "BOSH_USER" => username, "BOSH_PASSWORD" => password })

      bosh.upload_stemcell("/path/to/a/stemcell.tgz")
    end
  end

  describe ".upload_release" do
    it "runs the command to upload a " do
      expect(command_runner).to receive(:run).with(%{bosh -n --color -t #{target} upload release /path/to/a/release.tgz --skip-if-exists}, { "BOSH_USER" => username, "BOSH_PASSWORD" => password })

      bosh.upload_release("/path/to/a/release.tgz")
    end
  end

  describe ".deploy" do
    it "runs the command to upload a " do
      expect(command_runner).to receive(:run).with(%{bosh -n --color -t #{target} -d /path/to/a/manifest.yml deploy}, { "BOSH_USER" => username, "BOSH_PASSWORD" => password })

      bosh.deploy("/path/to/a/manifest.yml")
    end
  end

  describe "fetching the latest timestamp of a bosh deployment" do
    context "when deployments are found" do
      before do
        stub_request(:get, "http://bosh-user%CE%A9%CE%A9%CE%A9%CE%A9:bosh-password%21%23%25%26%23%28%2A@bosh.example.com/tasks?state=done").
          to_return(:body => response)
      end

      it "gets the time of the last finished deployment" do
        time = bosh.last_deployment_time("concourse")

        expect(time).to eq(Time.at(1427137404))
      end
    end

    context "when no deployments are found" do
      before do
        stub_request(:get, "http://bosh-user%CE%A9%CE%A9%CE%A9%CE%A9:bosh-password%21%23%25%26%23%28%2A@bosh.example.com/tasks?state=done").
          to_return(:body => "[]")
      end

      it "gets the time of the last finished deployment" do
        time = bosh.last_deployment_time("concourse")

        expect(time).to be_nil
      end
    end
  end
end
