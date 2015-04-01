require "spec_helper"

require "fileutils"
require "json"
require "open3"
require "tmpdir"
require "stringio"

describe "Out Command" do
  let(:manifest) { instance_double(BoshDeploymentResource::BoshManifest, use_stemcell: nil, use_release: nil, name: "bosh-deployment") }
  let(:bosh) { instance_double(BoshDeploymentResource::Bosh, upload_stemcell: nil, upload_release: nil, deploy: nil, last_deployment_time: Time.at(1234567890)) }
  let(:response) { StringIO.new }
  let(:command) { BoshDeploymentResource::OutCommand.new(bosh, manifest, response) }

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
    allow(manifest).to receive(:write!).and_return("/tmp/awesome/manifest.yml")
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

    it "generates a new manifest (with locked down versions) and deploys it" do
      in_dir do |working_dir|
        add_default_artefacts working_dir

        expect(manifest).to receive(:use_release)
        expect(manifest).to receive(:use_stemcell)

        expect(bosh).to receive(:deploy).with("/tmp/awesome/manifest.yml")

        command.run(working_dir, request)
      end
    end
  end

  context "with invalid inputs" do
    it "requires a target" do
      in_dir do |working_dir|
        expect do
          command.run(working_dir, {
            "source" => {
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
        end.to raise_error /source must include 'target'/
      end
    end

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

    it "requires a username" do
      in_dir do |working_dir|
        expect do
          command.run(working_dir, {
            "source" => {
              "target" => "http://bosh.example.com",
              "password" => "bosh-password",
              "deployment" => "bosh-deployment",
            },
            "params" => {
              "manifest" => "deployment.yml",
              "stemcells" => [],
              "releases" => []
            }
          })
        end.to raise_error /source must include 'username'/
      end
    end

    it "requires a password" do
      in_dir do |working_dir|
        expect do
          command.run(working_dir, {
            "source" => {
              "target" => "http://bosh.example.com",
              "username" => "bosh-username",
              "deployment" => "bosh-deployment",
            },
            "params" => {
              "manifest" => "deployment.yml",
              "stemcells" => [],
              "releases" => []
            }
          })
        end.to raise_error /source must include 'password'/
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
