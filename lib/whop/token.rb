require "jwt"
require "openssl"

module Whop
  module Token
    JWT_PEM = <<~PEM.freeze
      -----BEGIN PUBLIC KEY-----
      MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAErz8a8vxvexHC0TLT91g7llOdDOsN
      uYiGEfic4Qhni+HMfRBuUphOh7F3k8QgwZc9UlL0AHmyYqtbhL9NuJes6w==
      -----END PUBLIC KEY-----
    PEM

    module_function

    def verify(headers)
      token = headers["x-whop-user-token"] || headers["X-Whop-User-Token"]
      raise Whop::Error, "Missing x-whop-user-token header" if token.nil? || token.empty?
      payload = verify_from_jwt(token)
      app_id = payload["aud"]
      expected = ENV["WHOP_APP_ID"] || Whop.config.app_id
      raise Whop::Error, "Token audience mismatch" if expected && app_id != expected
      { "user_id" => payload["sub"] }
    end

    def verify_from_jwt(token)
      key = OpenSSL::PKey::EC.new(JWT_PEM)
      payload, _header = JWT.decode(token, key, true, {
        iss: "urn:whopcom:exp-proxy",
        verify_iss: true,
        algorithm: "ES256"
      })
      payload
    end
  end
end


