require "openssl"

module Whop
  module Webhooks
    module Signature
      module_function

      # Compute hex HMAC-SHA256 digest of the given payload using the secret.
      def compute(secret, payload)
        OpenSSL::HMAC.hexdigest("SHA256", secret, payload.to_s)
      end

      # Compare provided signature header to computed digest in constant time.
      # Accepts formats like "sha256=<hex>" or raw hex.
      def valid?(secret, payload, provided)
        return false if secret.to_s.empty? || payload.nil? || provided.to_s.empty?
        given = provided.to_s
        given = given.split("=", 2).last if given.include?("=")
        expected_primary = compute(secret, payload)
        return true if secure_compare(expected_primary, given)
        # Fallback: tolerate JSON formatting differences (dev convenience)
        normalized = normalize_json(payload)
        if normalized
          expected_canonical = compute(secret, normalized)
          return true if secure_compare(expected_canonical, given)
        end
        false
      end

      def normalize_json(payload)
        begin
          obj = JSON.parse(payload)
          JSON.generate(obj)
        rescue StandardError
          nil
        end
      end

      # Constant-time comparison to avoid timing attacks.
      def secure_compare(a, b)
        return false unless a.bytesize == b.bytesize
        l = a.unpack("C*")
        r = b.unpack("C*")
        result = 0
        l.zip(r) { |x, y| result |= x ^ y }
        result.zero?
      end
    end
  end
end


