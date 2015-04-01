require "spec_helper"

response = <<-EOS
[
  {
    "id": 54,
    "state": "error",
    "description": "create deployment",
    "timestamp": 1427905795,
    "result": "(<unknown>): mapping values are not allowed in this context at line 1 column 32",
    "user": "admin"
  },
  {
    "id": 50,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1427733902,
    "result": "/deployments/concourse-testflight",
    "user": "admin"
  },
  {
    "id": 48,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1427733792,
    "result": "/deployments/garden-testflight",
    "user": "admin"
  },
  {
    "id": 45,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1427733727,
    "result": "/deployments/concourse-testflight",
    "user": "admin"
  },
  {
    "id": 40,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1427137404,
    "result": "/deployments/concourse",
    "user": "admin"
  },
  {
    "id": 39,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1427135263,
    "result": "/deployments/concourse",
    "user": "admin"
  },
  {
    "id": 36,
    "state": "error",
    "description": "create deployment",
    "timestamp": 1427134960,
    "result": "`worker/0' is not running after update",
    "user": "admin"
  },
  {
    "id": 34,
    "state": "error",
    "description": "create deployment",
    "timestamp": 1427134795,
    "result": "Action Failed get_task: Task 0510178d-6d79-493c-5070-379030c425c1 result: Compiling package blackbox: Running packaging script:...",
    "user": "admin"
  },
  {
    "id": 33,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1427134322,
    "result": "/deployments/concourse",
    "user": "admin"
  },
  {
    "id": 31,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1426812960,
    "result": "/deployments/garden-testflight",
    "user": "admin"
  },
  {
    "id": 27,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1426544576,
    "result": "/deployments/garden-testflight",
    "user": "admin"
  },
  {
    "id": 25,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1426542811,
    "result": "/deployments/garden-testflight",
    "user": "admin"
  },
  {
    "id": 22,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1426542595,
    "result": "/deployments/concourse-testflight",
    "user": "admin"
  },
  {
    "id": 21,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1426542530,
    "result": "/deployments/garden-testflight",
    "user": "admin"
  },
  {
    "id": 18,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1426542397,
    "result": "/deployments/concourse-testflight",
    "user": "admin"
  },
  {
    "id": 17,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1426542339,
    "result": "/deployments/garden-testflight",
    "user": "admin"
  },
  {
    "id": 14,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1426541975,
    "result": "/deployments/concourse-testflight",
    "user": "admin"
  },
  {
    "id": 13,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1426541913,
    "result": "/deployments/garden-testflight",
    "user": "admin"
  },
  {
    "id": 11,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1426541856,
    "result": "/deployments/concourse-testflight",
    "user": "admin"
  },
  {
    "id": 6,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1426540834,
    "result": "/deployments/garden-testflight",
    "user": "admin"
  },
  {
    "id": 4,
    "state": "done",
    "description": "create deployment",
    "timestamp": 1426540775,
    "result": "/deployments/concourse-testflight",
    "user": "admin"
  }
]
EOS

describe BoshDeploymentResource::Bosh do
  let(:target) { "http://bosh.example.com" }
  let(:username) { "bosh-user" }
  let(:password) { "bosh-password" }

  let(:bosh) { BoshDeploymentResource::Bosh.new(target, username, password) }

  describe "fetching the latest timestamp of a bosh deployment" do


    context "when deployments are found" do
      before do
        stub_request(:get, "http://bosh.example.com/tasks?state=done").
          to_return(:body => response)
      end

      it "gets the time of the last finished deployment" do
        time = bosh.last_deployment_time("concourse")

        expect(time).to eq(Time.at(1427137404))
      end
    end

    context "when no deployments are found" do
      before do
        stub_request(:get, "http://bosh.example.com/tasks?state=done").
          to_return(:body => "[]")
      end

      it "gets the time of the last finished deployment" do
        time = bosh.last_deployment_time("concourse")

        expect(time).to be_nil
      end
    end
  end
end
