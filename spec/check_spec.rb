require "spec_helper"

require "json"
require "open3"

describe "Check Command" do
  let(:bosh) { instance_double(BoshDeploymentResource::Bosh, download_manifest: nil) }
  let(:writer) { StringIO.new }
  let(:request) {
    {
      "source" => {
        "target" => "http://bosh.example.com",
        "username" => "bosh-username",
        "password" => "bosh-password",
        "deployment" => "bosh-deployment",
      },
    }
  }

  let(:command) { BoshDeploymentResource::CheckCommand.new(bosh, writer) }

  it "outputs the version as the sha1sum of the downloaded manifest" do
    Dir.mktmpdir do |working_dir|
      expect(bosh).to receive(:download_manifest) do |dep, man|
        File.open(File.join(working_dir, 'manifest.yml'), 'w+') do |f|
          f.write("manifest_content\n")
        end
      end

      command.run(working_dir, request)
    end

    expected = [ {"manifest_sha1" => "d62bda40910dc867ebedb52052e6ae56111fe152"} ]

    writer.rewind
    output = JSON.parse(writer.read)
    expect(output).to eq(expected)
  end
end
