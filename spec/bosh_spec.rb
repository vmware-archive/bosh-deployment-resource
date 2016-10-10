require "spec_helper"

describe BoshDeploymentResource::CommandRunner do
  let (:command_runner) { BoshDeploymentResource::CommandRunner.new }

  describe '.run' do
    it 'takes a command and an environment and spanws a process' do
      expect {
        command_runner.run('sh -c "$PROG"', "PROG" => "true")
      }.to_not raise_error
    end

    it 'takes an options hash' do
      r, w = IO.pipe
      command_runner.run('sh -c "echo $FOO"', {"FOO" => "sup"}, out: w)
      expect(r.gets).to eq("sup\n")
    end

    it 'raises an exception if the command fails' do
      expect {
        command_runner.run('sh -c "$PROG"', "PROG" => "false")
      }.to raise_error("command 'sh -c \"$PROG\"' failed!")
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
  let(:auth) { BoshDeploymentResource::Auth.parse({"username" => username, "password" => password}) }
  let(:username) { "bosh-userΩΩΩΩ" }
  let(:password) { "bosh-password!#%&#(*" }
  let(:command_runner) { instance_double(BoshDeploymentResource::CommandRunner) }

  let(:bosh) { BoshDeploymentResource::Bosh.new(target, ca_cert, auth, command_runner) }
  let(:ca_cert) { BoshDeploymentResource::CaCert.new(nil) }

  describe ".upload_stemcell" do
    it "runs the command to upload a stemcell" do
      expect(command_runner).to receive(:run).with(%{bosh -n --color -t #{target} upload stemcell /path/to/a/stemcell.tgz --skip-if-exists}, { "BOSH_USER" => username, "BOSH_PASSWORD" => password }, {})

      bosh.upload_stemcell("/path/to/a/stemcell.tgz")
    end
  end

  describe ".upload_release" do
    it "runs the command to upload a release" do
      expect(command_runner).to receive(:run).with(%{bosh -n --color -t #{target} upload release /path/to/a/release.tgz --skip-if-exists}, { "BOSH_USER" => username, "BOSH_PASSWORD" => password }, {})

      bosh.upload_release("/path/to/a/release.tgz")
    end
  end

  describe ".deploy" do
    it "runs the command to deploy" do
      expect(command_runner).to receive(:run).with(%{bosh -n --color -t #{target} -d /path/to/a/manifest.yml deploy}, { "BOSH_USER" => username, "BOSH_PASSWORD" => password }, {})

      bosh.deploy("/path/to/a/manifest.yml")
    end

    it "runs the command to deploy with --no-redact" do
      expect(command_runner).to receive(:run).with(%{bosh -n --color -t #{target} -d /path/to/a/manifest.yml deploy --no-redact}, { "BOSH_USER" => username, "BOSH_PASSWORD" => password}, {})
      bosh.deploy("/path/to/a/manifest.yml",true)
    end
  end


  describe ".director_uuid" do
    it "collects the output of status --uuid" do
      expect(command_runner).to receive(:run).with(%{bosh -n --color -t #{target} status --uuid}, { "BOSH_USER" => username, "BOSH_PASSWORD" => password }, anything) do |_, _, opts|
        opts[:out].puts "abcdef\n"
      end

      expect(bosh.director_uuid).to eq("abcdef")
    end
  end

  describe ".download_manifest" do
    it "downloads the manifest" do
      expect(command_runner).to receive(:run).with(%{bosh -n --color -t #{target} download manifest test_deployment manifest_path}, { "BOSH_USER" => username, "BOSH_PASSWORD" => password }, {})
      bosh.download_manifest("test_deployment", "manifest_path")
    end
  end

  context "when ca_cert_path is provided" do
    let(:ca_cert) { BoshDeploymentResource::CaCert.new("fake-ca-cert-content") }
    after { ca_cert.cleanup }

    it "passes ca_cert to bosh cli" do
      expect(command_runner).to receive(:run).with(%{bosh -n --color -t #{target} --ca-cert #{ca_cert.path} -d /path/to/a/manifest.yml deploy}, anything, anything)

      bosh.deploy("/path/to/a/manifest.yml")
    end
  end
end
