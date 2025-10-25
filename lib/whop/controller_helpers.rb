module Whop
  module ControllerHelpers
    private

    def whop_user_id
      # Primary: verified JWT from header
      token = request.headers["x-whop-user-token"] || request.headers["X-Whop-User-Token"]
      if token && !token.to_s.empty?
        payload = Whop::Token.verify_from_jwt(token)
        app_id = payload["aud"]
        raise Whop::Error, "Invalid app audience" if app_id != (ENV["WHOP_APP_ID"] || Whop.config.app_id)
        return payload["sub"]
      end

      # Development fallback: support whop-dev-user-token (header or param)
      if defined?(Rails) && Rails.env.development?
        dev_token = request.get_header("HTTP_WHOP_DEV_USER_TOKEN") || request.headers["whop-dev-user-token"] || params["whop-dev-user-token"] || params[:whop_dev_user_token]
        if dev_token && !dev_token.to_s.empty?
          # If looks like JWT, try to verify; otherwise treat as direct user_id
          if dev_token.to_s.include?(".")
            payload = Whop::Token.verify_from_jwt(dev_token)
            return payload["sub"]
          else
            return dev_token
          end
        end
      end

      nil
    end

    # Alias for readability
    def current_whop_user_id
      whop_user_id
    end

    # Ensure a valid Whop user token is present, otherwise raise
    def require_whop_user!
      uid = whop_user_id
      raise Whop::Error, "Missing Whop user token" if uid.nil?
      uid
    end

    # Convenience: fetch the current Whop user resource via REST SDK
    def current_whop_user
      uid = require_whop_user!
      Whop.sdk.users.retrieve(uid)
    rescue StandardError
      nil
    end

    def require_whop_access!(experience_id: nil, access_pass_id: nil, company_id: nil)
      uid = whop_user_id
      raise Whop::Error, "Missing Whop user token" if uid.nil?

      resource_id = experience_id || access_pass_id || company_id

      has_access = true
      if resource_id
        resp = Whop.sdk.users.check_access(resource_id, id: uid)
        has_access = if resp.respond_to?(:has_access)
          resp.has_access
        else
          (resp["has_access"] || resp[:has_access])
        end
      end

      render plain: "Forbidden", status: :forbidden unless has_access
    end
  end
end


