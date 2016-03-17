require "spec_helper"

require "json"
require "open3"

describe "Check Command" do
  let(:bosh) { instance_double(BoshDeploymentResource::Bosh, download_manifest: nil) }
  let(:writer) { StringIO.new }
  let(:request) {
    {
      "source" => {
        "username" => "bosh-username",
        "password" => "bosh-password",
        "deployment" => "bosh-deployment",
      },
      "version" => {
        "manifest_sha1" => "some-sha"
      }
    }
  }

  let(:manifest_from_bosh) { <<EOF
---
qux:
  corge: grault
wiff:
- a
- b
- c
foo:
  bar: baz
EOF
  }

  let(:command) { BoshDeploymentResource::CheckCommand.new(bosh, writer) }

  context "when the source does have a target" do
    before do
      allow(bosh).to receive(:target).and_return("bosh-target")
    end

    it "downloads the manifest" do
      expect(bosh).to receive(:download_manifest).with("bosh-deployment", anything) do |_, manifest_path|
        File.open(manifest_path, 'w+') do |f|
          f.write(manifest_from_bosh)
        end
      end
      command.run(request)
    end

    context "when the provided version differs from the downloaded manifest's sha" do
      before do
        request["version"] = {
          "manifest_sha1" => "different-sha"
        }
      end

      it "outputs the version as the sha of the values of the sorted, parsed manifest" do
        allow(bosh).to receive(:download_manifest) do |_, path|
          File.open(path, 'w+') do |f|
            f.write(manifest_from_bosh)
          end
        end

        command.run(request)

        d = Digest::SHA1.new
        d << 'foo'      # foo:
        d << 'bar'      #   bar: baz
        d << 'baz'      #
        d << 'qux'      # qux:
        d << 'corge'    #   corge: grault
        d << 'grault'   #
        d << 'wiff'     # wiff:
        d << 'a'        # - a
        d << 'b'        # - b
        d << 'c'        # - c

        expected = [ {"manifest_sha1" => d.hexdigest} ]

        writer.rewind
        output = JSON.parse(writer.read)
        expect(output).to eq(expected)
      end
    end

    context "when the provided version is the same as the downloaded manifest's sha" do
      before do
        request["version"] = {
          "manifest_sha1" => "e530a7b5a47f1887b2e48a45c1895cb3f8eb032f"
        }
      end

      it "outputs an empty array" do
        allow(bosh).to receive(:download_manifest) do |_, path|
          File.open(path, 'w+') do |f|
            f.write(manifest_from_bosh)
          end
        end

        command.run(request)

        writer.rewind
        output = JSON.parse(writer.read)
        expect(output).to eq([])
      end

      it "performs a content-aware shasum" do
        reordered_but_equivalent_manifest_from_bosh = <<EOF
---
foo:
  bar: baz
qux:
  corge: grault
wiff:
- a
- b
- c
EOF

        allow(bosh).to receive(:download_manifest) do |_, path|
          File.open(path, 'w+') do |f|
            f.write(reordered_but_equivalent_manifest_from_bosh)
          end
        end

        command.run(request)

        writer.rewind
        output = JSON.parse(writer.read)
        expect(output).to eq([])
      end
    end
  end

  context "when the source does not have a target" do
    before do
      allow(bosh).to receive(:target).and_return(nil)
    end

    it "does not try to download the manifest" do
      expect(bosh).not_to receive(:download_manifest)
      command.run(request)
    end

    it "outputs an empty array of versions" do
      command.run(request)

      writer.rewind
      output = JSON.parse(writer.read)
      expect(output).to eq([])
    end
  end
end
