require "spec_helper"

require "digest"
require "fileutils"
require "json"
require "open3"
require "tmpdir"
require "stringio"

describe "Out Command" do
  let(:manifest) { instance_double(BoshDeploymentResource::BoshManifest, fallback_director_uuid: nil, use_stemcell: nil, use_release: nil, name: "bosh-deployment", validate_stemcells: nil, shasum: "1234") }
  let(:bosh) { instance_double(BoshDeploymentResource::Bosh, upload_stemcell: nil, upload_release: nil, deploy: nil, director_uuid: "some-director-uuid", target: "bosh-target") }
  let(:response) { StringIO.new }
  let(:command) { BoshDeploymentResource::OutCommand.new(bosh, manifest, response) }

  let(:written_manifest) do
    file = Tempfile.new("bosh_manifest")
    file.write("hello world")
    file.close
    file
  end

  def touch(*paths)
    path = File.join(paths)
    FileUtils.mkdir_p(File.dirname(path))
    FileUtils.touch(path)
  end

  def cp(src, *paths)
    path = File.join(paths)
    FileUtils.mkdir_p(File.dirname(path))
    FileUtils.cp(src, path)
  end

  def in_dir
    Dir.mktmpdir do |working_dir|
      yield working_dir
    end
  end

  def add_default_artefacts(working_dir)
    cp "spec/fixtures/stemcell.tgz", working_dir, "stemcells", "stemcell.tgz"
    cp "spec/fixtures/stemcell.tgz", working_dir, "stemcells", "other-stemcell.tgz"
    touch working_dir, "stemcells", "not-stemcell.txt"

    cp "spec/fixtures/release.tgz", working_dir, "releases", "release.tgz"
    cp "spec/fixtures/release.tgz", working_dir, "releases", "other-release.tgz"
    touch working_dir, "releases", "not-release.txt"
  end

  before do
    allow(manifest).to receive(:write!).and_return(written_manifest)
  end

  let(:request) {
    {
      "source" => {
        "target" => "http://bosh.example.com",
        "username" => "bosh-username",
        "password" => "bosh-password",
        "deployment" => "bosh-deployment",
      },
      "params" => {
        "manifest" => "manifest/deployment.yml",
        "stemcells" => [
          "stemcells/*.tgz"
        ],
        "releases" => [
          "releases/*.tgz"
        ]
      }
    }
  }

  context "with valid inputs" do
    it "uploads matching stemcells to the director" do
      in_dir do |working_dir|
        add_default_artefacts working_dir

        expect(bosh).to receive(:upload_stemcell).
          with(File.join(working_dir, "stemcells", "stemcell.tgz"))
        expect(bosh).to receive(:upload_stemcell).
          with(File.join(working_dir, "stemcells", "other-stemcell.tgz"))

        command.run(working_dir, request)
      end
    end

    it "emits the version as the manifest_sha1 and target" do
      in_dir do |working_dir|
        add_default_artefacts working_dir

        command.run(working_dir, request)

        expect(JSON.parse(response.string)["version"]).to eq({
          "manifest_sha1" => manifest.shasum,
          "target" => "bosh-target",
        })
      end
    end

    it "emits the release/stemcell versions in the metadata" do
      in_dir do |working_dir|
        add_default_artefacts working_dir

        command.run(working_dir, request)

        expect(JSON.parse(response.string)["metadata"]).to eq([
          {"name" => "stemcell", "value" => "bosh-aws-xen-hvm-ubuntu-trusty-go_agent v2905"},
          {"name" => "stemcell", "value" => "bosh-aws-xen-hvm-ubuntu-trusty-go_agent v2905"},
          {"name" => "release", "value" => "concourse v0.43.0"},
          {"name" => "release", "value" => "concourse v0.43.0"}
        ])
      end
    end

    it "handles overlapping stemcell globs by removing duplication" do
      request.fetch("params").store("stemcells", [
        "stemcells/*.tgz",
        "stemcells/*.tgz"
      ])

      in_dir do |working_dir|
        add_default_artefacts working_dir

        expect(bosh).to receive(:upload_stemcell).exactly(2).times

        command.run(working_dir, request)
      end
    end

    it "uploads matching releases to the director" do
      in_dir do |working_dir|
        add_default_artefacts working_dir

        expect(bosh).to receive(:upload_release).
          with(File.join(working_dir, "releases", "release.tgz"))
        expect(bosh).to receive(:upload_release).
          with(File.join(working_dir, "releases", "other-release.tgz"))

        command.run(working_dir, request)
      end
    end

    it "handles overlapping release globs by removing duplication" do
      request.fetch("params").store("releases", [
        "releases/*.tgz",
        "releases/*.tgz"
      ])

      in_dir do |working_dir|
        add_default_artefacts working_dir

        expect(bosh).to receive(:upload_release).exactly(2).times

        command.run(working_dir, request)
      end
    end

    it "generates a new manifest (with locked down versions and a defaulted director uuid) and deploys it" do
      in_dir do |working_dir|
        add_default_artefacts working_dir

        expect(bosh).to receive(:director_uuid).and_return("abcdef")
        expect(manifest).to receive(:use_release)
        expect(manifest).to receive(:use_stemcell)
        expect(manifest).to receive(:fallback_director_uuid).with("abcdef")

        expect(bosh).to receive(:deploy).with(written_manifest.path,false)

        command.run(working_dir, request)
      end
    end

    it "does NOT run a bosh cleanup when the cleanup parameter is NOT passed" do
      in_dir do |working_dir|
        add_default_artefacts working_dir

        expect(bosh).not_to receive(:cleanup)

        command.run(working_dir, request)
      end
    end


    it "runs a bosh cleanup when the cleanup parameter is set to true" do
      request.fetch("params").store("cleanup", true)

      in_dir do |working_dir|
        add_default_artefacts working_dir

        expect(bosh).to receive(:cleanup)

        command.run(working_dir, request)
      end
    end


    it "does update a bosh manifest with stemcell and releases when the no_version_update parameter is NOT passed" do
      in_dir do |working_dir|
        add_default_artefacts working_dir

        expect(manifest).to receive(:use_stemcell)
        expect(manifest).to receive(:use_release)

        command.run(working_dir, request)
      end
    end

    it "does NOT update a bosh manifest with stemcell and releases when the no_version_update parameter set to true" do
      request.fetch("params").store("no_version_update", true)

      in_dir do |working_dir|
        add_default_artefacts working_dir

        expect(manifest).to_not receive(:use_stemcell)
        expect(manifest).to_not receive(:use_release)

      end
    end

    it "runs a bosh no-redact when the no_redact parameter is set to true" do
      request.fetch("params").store("no_redact", true)

      in_dir do |working_dir|
        add_default_artefacts working_dir
        expect(bosh).to receive(:deploy).with(anything,true)
        command.run(working_dir, request)
      end
    end

  end

  context "with invalid inputs" do
    it "errors if the given deployment name and the name in the manifest do not match" do
      allow(manifest).to receive(:name).and_return("other-name")

      in_dir do |working_dir|
        expect do
          command.run(working_dir, {
            "source" => {
              "target" => "http://bosh.example.com",
              "username" => "bosh-user",
              "password" => "bosh-password",
              "deployment" => "bosh-deployment",
            },
            "params" => {
              "manifest" => "deployment.yml",
              "stemcells" => [],
              "releases" => []
            }
          })
        end.to raise_error /given deployment name 'bosh-deployment' does not match manifest name 'other-name'/
      end
    end

    it "errors when provided stemcells cannot be validated against the manifest" do
      allow(manifest).to receive(:validate_stemcells).and_raise("invalid")

      in_dir do |working_dir|
        add_default_artefacts working_dir

        expect(bosh).to_not receive(:upload_stemcell)

        expect do
          command.run(working_dir, request)
        end.to raise_error "invalid"
      end
    end

    it "requires a deployment" do
      in_dir do |working_dir|
        expect do
          command.run(working_dir, {
            "source" => {
              "target" => "http://bosh.example.com",
              "username" => "bosh-username",
              "password" => "bosh-password",
            },
            "params" => {
              "manifest" => "deployment.yml",
              "stemcells" => [],
              "releases" => []
            }
          })
        end.to raise_error /source must include 'deployment'/
      end
    end

    it "requires a manifest" do
      in_dir do |working_dir|
        expect do
          command.run(working_dir, {
            "source" => {
              "target" => "http://bosh.example.com",
              "username" => "bosh-username",
              "password" => "bosh-password",
              "deployment" => "bosh-deployment",
            },
            "params" => {
              "stemcells" => [],
              "releases" => []
            }
          })
        end.to raise_error /params must include 'manifest'/
      end
    end

    it "errors if the cleanup paramater is NOT a boolean value" do
      in_dir do |working_dir|
        expect do
          command.run(working_dir, {
            "source" => {
              "target" => "http://bosh.example.com",
              "username" => "bosh-username",
              "password" => "bosh-password",
              "deployment" => "bosh-deployment",
            },
            "params" => {
              "manifest" => "deployment.yml",
              "stemcells" => [],
              "releases" => [],
              "cleanup" => 1
            }
          })
        end.to raise_error /given cleanup value must be a boolean/
      end
    end


    it "errors if the no_redact paramater is NOT a boolean value" do
      in_dir do |working_dir|
        expect do
          command.run(working_dir, {
            "source" => {
              "target" => "http://bosh.example.com",
              "username" => "bosh-username",
              "password" => "bosh-password",
              "deployment" => "bosh-deployment",
            },
            "params" => {
              "manifest" => "deployment.yml",
              "stemcells" => [],
              "releases" => [],
              "no_redact" => 1
            }
          })
        end.to raise_error /given no_redact value must be a boolean/
      end
    end

    it "errors if the no_version_update paramater is NOT a boolean value" do
      in_dir do |working_dir|
        expect do
          command.run(working_dir, {
            "source" => {
              "target" => "http://bosh.example.com",
              "username" => "bosh-username",
              "password" => "bosh-password",
              "deployment" => "bosh-deployment",
            },
            "params" => {
              "manifest" => "deployment.yml",
              "stemcells" => [],
              "releases" => [],
              "no_version_update" => 1
            }
          })
        end.to raise_error /given no_version_update value must be a boolean/
      end
    end

    describe "stemcell and release globs" do
      it "errors if the stemcells are not an array" do
        in_dir do |working_dir|
          expect do
            command.run(working_dir, {
              "source" => {
                "target" => "http://bosh.example.com",
                "username" => "bosh-username",
                "password" => "bosh-password",
                "deployment" => "bosh-deployment",
              },
              "params" => {
                "manifest" => "deployment.yml",
                "stemcells" => "stemcell.tgz",
                "releases" => []
              }
            })
          end.to raise_error /stemcells must be an array of globs/
        end
      end

      it "errors if the stemcells are not an array" do
        in_dir do |working_dir|
          expect do
            command.run(working_dir, {
              "source" => {
                "target" => "http://bosh.example.com",
                "username" => "bosh-username",
                "password" => "bosh-password",
                "deployment" => "bosh-deployment",
              },
              "params" => {
                "manifest" => "deployment.yml",
                "stemcells" => [],
                "releases" => "release.tgz"
              }
            })
          end.to raise_error /releases must be an array of globs/
        end
      end

      it "errors if a glob resolves to an empty list of files" do
        in_dir do |working_dir|
          touch working_dir, "stemcells", "stemcell.tgz"
          touch working_dir, "releases", "release.rtf"

          expect do
            command.run(working_dir, request)
          end.to raise_error "glob 'releases/*.tgz' matched no files"
        end
      end
    end
  end
end
