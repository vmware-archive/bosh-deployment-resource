require "spec_helper"

require "yaml"

describe BoshDeploymentResource::BoshManifest do
  let(:manifest) { BoshDeploymentResource::BoshManifest.new("spec/fixtures/manifest.yml") }

  let(:resulting_manifest) { YAML.load_file(manifest.write!) }

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
        }
      ]
    end

end
