module BoshDeploymentResource
  class Auth
    def self.parse(options)
      default_auth = options[:username] || options[:password]
      uaa_auth = options[:client_id] || options[:client_secret]
      case
        when default_auth && uaa_auth
          raise "source must include either username/password or client_id/client_secret, but not both"
        when default_auth
          return DefaultAuth.parse(options)
        when uaa_auth
          return UaaAuth.parse(options)
        else
          raise "source must include either username/password or client_id/client_secret"
      end
    end
  end

  private

  class DefaultAuth
    def self.parse(options)
      if !options[:username] || !options[:password]
        raise "source must include both 'username' and 'password'"
      end

      new(options.fetch(:username), options.fetch(:password))
    end

    def initialize(username, password)
      @username = username
      @password = password
    end

    def env
      { "BOSH_USER" => @username, "BOSH_PASSWORD" => @password }
    end
  end

  class UaaAuth
    def self.parse(options)
      if !options[:client_id] || !options[:client_secret]
        raise "source must include both 'client_id' and 'client_secret'"
      end

      new(options.fetch(:client_id), options.fetch(:client_secret))
    end

    def initialize(client_id, client_secret)
      @client_id = client_id
      @client_secret = client_secret
    end

    def env
      { "BOSH_CLIENT" => @client_id, "BOSH_CLIENT_SECRET" => @client_secret }
    end
  end
end
