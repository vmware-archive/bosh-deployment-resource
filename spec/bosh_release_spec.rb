require "spec_helper"

describe BoshDeploymentResource::BoshRelease do
  context "for a tarball release" do
    let(:release) { BoshDeploymentResource::BoshRelease.new("spec/fixtures/release.tgz") }

    it "can detect the name of the release" do
      expect(release.name).to eq("concourse")
    end

    it "can detect the version number of a release" do
      expect(release.version).to eq("0.43.0")
    end

    it "caches the result (if this test takes a long time then you broke it)" do
      1000.times do
        release.name
        release.version
      end
    end
  end

  context "for a manifest release" do
    let(:release) { BoshDeploymentResource::BoshRelease.new("spec/fixtures/release.yml") }

    it "can detect the name of the release" do
      expect(release.name).to eq("concourse")
    end

    it "can detect the version number of a release" do
      expect(release.version).to eq("0.43.0")
    end
  end
end
