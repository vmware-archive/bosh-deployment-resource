require "spec_helper"

require "yaml"

describe BoshDeploymentResource::BoshManifest do
  let(:manifest) { BoshDeploymentResource::BoshManifest.new("spec/fixtures/manifest.yml") }
  let(:bosh_2_manifest) { BoshDeploymentResource::BoshManifest.new("spec/fixtures/bosh_2_manifest.yml") }

  let(:resulting_manifest) { YAML.load_file(manifest.write!) }
  let(:resulting_bosh_2_manifest) { YAML.load_file(bosh_2_manifest.write!) }

  it "can get the name of the deployment" do
    expect(manifest.name).to eq("concourse")
  end

  describe ".fallback_director_uuid" do
    let(:uuid) { "some-filled-in-uuid" }

    context "when the source manifest has no director uuid" do
      let(:manifest) { BoshDeploymentResource::BoshManifest.new("spec/fixtures/manifest-without-uuid.yml") }

      it "fills it in with the given uuid" do
        manifest.fallback_director_uuid(uuid)
        expect(resulting_manifest.fetch("director_uuid")).to eq("some-filled-in-uuid")
      end
    end

    context "when the source manifest already has a uuid" do
      let(:manifest) { BoshDeploymentResource::BoshManifest.new("spec/fixtures/manifest-with-uuid.yml") }

      it "does not replace it" do
        manifest.fallback_director_uuid(uuid)
        expect(resulting_manifest.fetch("director_uuid")).to eq("some-director-uuid")
      end
    end
  end

  it "can replace the releases used in a manifest" do
    concourse = instance_double(BoshDeploymentResource::BoshRelease, name: "concourse", version: "1234")
    garden = instance_double(BoshDeploymentResource::BoshRelease, name: "garden-linux", version: "9876")

    manifest.use_release(concourse)
    manifest.use_release(garden)

    releases = resulting_manifest.fetch("releases")

    expect(releases).to match_array [
      {
        "name" => "concourse",
        "version" => "1234",
      },
      {
        "name" => "garden-linux",
        "version" => "9876",
      }
    ]
  end

  context "when manifest specifies stemcells with stemcell key" do
    it "can replace the stemcells used in a manifest" do
      centos_stemcell = instance_double(
        BoshDeploymentResource::BoshStemcell,
        name: "bosh-warden-boshlite-centos-7-go_agent",
        os: "",
        version: "9832"
      )

      trusty_stemcell = instance_double(
        BoshDeploymentResource::BoshStemcell,
        name: "bosh-warden-boshlite-ubuntu-trusty-go_agent",
        os: "ubuntu-trusty",
        version: "4393"
      )

      bosh_2_manifest.use_stemcell(centos_stemcell)
      bosh_2_manifest.use_stemcell(trusty_stemcell)

      stemcells = resulting_bosh_2_manifest.fetch("stemcells")

      expect(stemcells).to match_array [
        {
          "name" => "bosh-warden-boshlite-centos-7-go_agent",
          "alias" => "centos",
          "version" => "9832"
        },
        {
          "os" => "ubuntu-trusty",
          "alias" => "trusty",
          "version" => "4393"
        },
        {
          "os" => "mac",
          "alias" => "powerpc",
          "version" => "latest"
        }
      ]
    end
  end

  context "when the manifest specifies stemcells in resource_pools key" do
    it "can replace the stemcells used in a manifest" do
      go_agent = instance_double(
        BoshDeploymentResource::BoshStemcell,
        name: "bosh-warden-boshlite-ubuntu-trusty-go_agent",
        version: "9832"
      )

      ruby_agent = instance_double(
        BoshDeploymentResource::BoshStemcell,
        name: "bosh-warden-boshlite-ubuntu-trusty-ruby_agent",
        version: "4393"
      )

      manifest.use_stemcell(go_agent)
      manifest.use_stemcell(ruby_agent)

      resource_pools = resulting_manifest.fetch("resource_pools")

      expect(resource_pools).to match_array [
        {
          "name" => "fast",
          "stemcell" => {
            "name" => "bosh-warden-boshlite-ubuntu-trusty-go_agent",
            "version" => "9832"
          }
        },
        {
          "name" => "other-fast",
          "stemcell" => {
            "name" => "bosh-warden-boshlite-ubuntu-trusty-go_agent",
            "version" => "9832"
          }
        },
        {
          "name" => "slow",
          "stemcell" => {
            "name" => "bosh-warden-boshlite-ubuntu-trusty-ruby_agent",
            "version" => "4393"
          }
        },
        {
          "name" => "non-latest",
          "stemcell" => {
            "name" => "bosh-warden-boshlite-ubuntu-trusty-ruby_agent",
            "version" => 1000
          }
        }
      ]
    end
  end

  it "errors if a release is called which isn't defined in the manifest releases list" do
    unfindable_release = double(name: "wrong_name", version: 0)

    expect do
      manifest.use_release(unfindable_release)
    end.to raise_error /#{unfindable_release.name} can not be found in manifest releases/
  end

  describe "#validate" do
    context "when each provided stemcell matches unique stemcell in manifest" do
      it "does not raise an error" do
        go_agent = instance_double(
          BoshDeploymentResource::BoshStemcell,
          name: "bosh-warden-boshlite-ubuntu-trusty-go_agent",
          version: "9832"
        )

        ruby_agent = instance_double(
          BoshDeploymentResource::BoshStemcell,
          name: "bosh-warden-boshlite-ubuntu-trusty-ruby_agent",
          version: "4393"
        )

        expect {
          manifest.validate_stemcells([go_agent, ruby_agent])
        }.to_not raise_error
      end
    end

    context "when there are multiple stemcells that match stemcell with latest version in manifest" do
      it "raises an error" do
        go_agent = instance_double(
          BoshDeploymentResource::BoshStemcell,
          name: "bosh-warden-boshlite-ubuntu-trusty-go_agent",
          version: "9832"
        )

        bumped_go_agent = instance_double(
          BoshDeploymentResource::BoshStemcell,
          name: "bosh-warden-boshlite-ubuntu-trusty-go_agent",
          version: "9833"
        )

        expect {
          manifest.validate_stemcells([go_agent, bumped_go_agent])
        }.to raise_error
      end
    end

    context "when there multiple stemcells that match stemcell in bosh 2.0 manifest by os/name" do
      it "raises an error" do
        trusty_stemcell = instance_double(
          BoshDeploymentResource::BoshStemcell,
          name: "bosh-warden-boshlite-ubuntu-trusty-go_agent",
          os: "ubuntu-trusty",
          version: "4393"
        )
        bumped_trusty_stemcell = instance_double(
          BoshDeploymentResource::BoshStemcell,
          name: "bosh-warden-boshlite-ubuntu-trusty-go_agent",
          os: "ubuntu-trusty",
          version: "4394"
        )

        expect {
          bosh_2_manifest.validate_stemcells([trusty_stemcell, bumped_trusty_stemcell])
        }.to raise_error
      end
    end
  end

  describe "#shasum" do
    it "outputs the version as the sha of the values of the sorted, parsed manifest" do
      actual = manifest.shasum

      d = Digest::SHA1.new

      d << 'name'                                             # name: concourse
      d << 'concourse'                                        #
      d << 'releases'                                         # releases:
      d << 'name'                                             #   - name: concourse
      d << 'concourse'                                        #
      d << 'version'                                          #     version: latest
      d << 'latest'                                           #
      d << 'name'                                             #   - name: garden-linux
      d << 'garden-linux'                                     #
      d << 'version'                                          #     version: latest
      d << 'latest'                                           #
      d << 'resource_pools'                                   # resource_pools:
      d << 'name'                                             #   - name: fast
      d << 'fast'                                             #
      d << 'stemcell'                                         #     stemcell:
      d << 'name'                                             #       name: bosh-warden-boshlite-ubuntu-trusty-go_agent
      d << 'bosh-warden-boshlite-ubuntu-trusty-go_agent'      #
      d << 'version'                                          #       version: latest
      d << 'latest'                                           #
      d << 'name'                                             #   - name: other-fast
      d << 'other-fast'                                       #
      d << 'stemcell'                                         #     stemcell:
      d << 'name'                                             #       name: bosh-warden-boshlite-ubuntu-trusty-go_agent
      d << 'bosh-warden-boshlite-ubuntu-trusty-go_agent'      #
      d << 'version'                                          #       version: latest
      d << 'latest'                                           #
      d << 'name'                                             #   - name: slow
      d << 'slow'                                             #
      d << 'stemcell'                                         #     stemcell:
      d << 'name'                                             #       name: bosh-warden-boshlite-ubuntu-trusty-ruby_agent
      d << 'bosh-warden-boshlite-ubuntu-trusty-ruby_agent'    #
      d << 'version'                                          #       version: latest
      d << 'latest'                                           #
      d << 'name'                                             #   - name: non-latest
      d << 'non-latest'                                       #
      d << 'stemcell'                                         #     stemcell:
      d << 'name'                                             #       name: bosh-warden-boshlite-ubuntu-trusty-ruby_agent
      d << 'bosh-warden-boshlite-ubuntu-trusty-ruby_agent'    #
      d << 'version'                                          #       version: 1000
      d << '1000'                                             #

      expect(actual).to eq(d.hexdigest)
    end
  end
end
