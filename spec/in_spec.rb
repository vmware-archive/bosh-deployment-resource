require "spec_helper"

require "json"
require "stringio"
require "time"

describe "In Command" do
  let(:working_dir) { "/haha/this/is/not/used" }
  let(:response) { StringIO.new }
  let(:command) { BoshDeploymentResource::InCommand.new(response) }

  def run_command
    command.run(working_dir, request)
    response.rewind
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
