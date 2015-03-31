require "spec_helper"

require "json"
require "open3"

describe "Check Command" do
  it "outputs and empty json list" do
    stdout, _, status = Open3.capture3("bdr_check")

    expect(status).to be_success
    expect(JSON.parse(stdout)).to eq([])
  end
end
