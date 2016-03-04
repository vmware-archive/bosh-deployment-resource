require "spec_helper"

describe BoshDeploymentResource::Auth do
  def parse(options)
    BoshDeploymentResource::Auth.parse(options)
  end

  describe "parse" do
    context "when username and password are provided" do
      it "does not raise an error" do
        expect { parse({"username" => "foo", "password" => "bar"}) }.to_not raise_error
      end
    end

    context "when client_id and client_secret are provided" do
      it "does not raise an error" do
        expect { parse({"client_id" => "foo", "client_secret" => "bar"}) }.to_not raise_error
      end
    end

    context "when incorrect options are provided" do
      it "raises an error" do
        expected_error_message = "source must include either username/password or client_id/client_secret, but not both"
        expect { parse({"username" => "foo", "client_id" => "bar"}) }.to raise_error(expected_error_message)
        expect { parse({"username" => "foo", "client_secret" => "bar"}) }.to raise_error(expected_error_message)
        expect { parse({"password" => "foo", "client_secret" => "bar"}) }.to raise_error(expected_error_message)
        expect {
          parse({"username" => "foo", "password" => "bar", "client_id" => "foo", "client_secret" => "bar"})
        }.to raise_error(expected_error_message)
      end
    end

    context "when neither username/password nor client_id/client_secret were provided" do
      it "raises an error" do
        expect { parse({}) }.to raise_error "source must include either username/password or client_id/client_secret"
      end
    end

    context "when username is provided but password is not" do
      it "raises an error" do
        expect { parse({"username" => "foo"}) }.to raise_error "source must include both 'username' and 'password'"
      end
    end

    context "when client_id is provided but client_secret is not" do
      it "raises an error" do
        expect { parse({"client_id" => "foo"}) }.to raise_error "source must include both 'client_id' and 'client_secret'"
      end
    end
  end

  describe "env" do
    context "when using username and password" do
      it "returns correct bosh environment variables" do
        auth = parse({"username" => "foo", "password" => "bar"})
        expect(auth.env).to eq({'BOSH_USER' => "foo", 'BOSH_PASSWORD' => "bar"})
      end
    end

    context "when using client_id and client_secret" do
      it "returns correct bosh environment variables" do
        auth = parse({"client_id" => "foo", "client_secret" => "bar"})
        expect(auth.env).to eq({'BOSH_CLIENT' => "foo", 'BOSH_CLIENT_SECRET' => "bar"})
      end
    end
  end
end
