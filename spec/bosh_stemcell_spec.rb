require "spec_helper"

describe BoshDeploymentResource::BoshStemcell do
  let(:stemcell) { BoshDeploymentResource::BoshStemcell.new("spec/fixtures/stemcell.tgz") }

  it "can detect the name of the stemcell" do
    expect(stemcell.name).to eq("bosh-aws-xen-hvm-ubuntu-trusty-go_agent")
  end

  it "can detect the version number of a stemcell" do
    expect(stemcell.version).to eq("2905")
  end

  it "can detect the operating system of a stemcell" do
    expect(stemcell.os).to eq("ubuntu-trusty")
  end

  it "caches the result (if this test takes a long time then you broke it)" do
    1000.times do
      stemcell.name
      stemcell.version
    end
  end
end
