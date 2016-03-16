require "spec_helper"

require "json"
require "stringio"
require "time"

describe "In Command" do
  let(:response) { StringIO.new }
  let(:bosh) { instance_double(BoshDeploymentResource::Bosh, download_manifest: nil) }
  let(:command) { BoshDeploymentResource::InCommand.new(bosh, response) }

  def run_command
    Dir.mktmpdir do |working_dir|
      command.run(working_dir, request)
      response.rewind
    end
  end

  context "when the version is given on STDIN" do
    let(:request) {
      {
        "source" => {
          "target" => "http://bosh.example.com",
          "username" => "bosh-username",
          "password" => "bosh-password",
          "deployment" => "bosh-deployment",
        },
        "version" => {
          "manifest_sha1" => "abcdef"
        }
      }
    }

    it "outputs the version that it was given" do
      run_command

      expected = {
        "version" => {
          "manifest_sha1" => "abcdef"
        }
      }

      output = JSON.parse(response.read)
      expect(output).to eq(expected)
    end

    it "downloads the manifest" do
      Dir.mktmpdir do |working_dir|
        expect(bosh).to receive(:download_manifest).with("bosh-deployment", File.join(working_dir, "manifest.yml"))
        command.run(working_dir, request)
      end
    end
  end

  context "when the version is not given on STDIN" do
    let(:request) {
      {
        "source" => {
          "target" => "http://bosh.example.com",
          "username" => "bosh-username",
          "password" => "bosh-password",
          "deployment" => "bosh-deployment",
        }
      }
    }

    it "fails" do
      expect { run_command }.to raise_error("no version specified")
    end
  end
end
