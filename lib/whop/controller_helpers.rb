module Whop
  module ControllerHelpers
    private

    def whop_user_id
      # Primary: verified JWT from header
      token = request.headers["x-whop-user-token"] || request.headers["X-Whop-User-Token"]
      if token.present?
        payload = Whop::Token.verify_from_jwt(token)
        app_id = payload["aud"]
        raise Whop::Error, "Invalid app audience" if app_id != (ENV["WHOP_APP_ID"] || Whop.config.app_id)
        return payload["sub"]
      end

      # Development fallback: support whop-dev-user-token (header or param)
      if defined?(Rails) && Rails.env.development?
        dev_token = request.get_header("HTTP_WHOP_DEV_USER_TOKEN") || request.headers["whop-dev-user-token"] || params["whop-dev-user-token"] || params[:whop_dev_user_token]
        if dev_token.present?
          # If looks like JWT, try to verify; otherwise treat as direct user_id
          if dev_token.include?(".")
            payload = Whop::Token.verify_from_jwt(dev_token)
            return payload["sub"]
          else
            return dev_token
          end
        end
      end

      nil
    end

    def require_whop_access!(experience_id: nil, access_pass_id: nil, company_id: nil)
      uid = whop_user_id
      raise Whop::Error, "Missing Whop user token" if uid.nil?

      has_access = if experience_id
        Whop.client.access.user_has_access_to_experience?(user_id: uid, experience_id: experience_id)
      elsif access_pass_id
        Whop.client.access.user_has_access_to_access_pass?(user_id: uid, access_pass_id: access_pass_id)
      elsif company_id
        Whop.client.access.user_has_access_to_company?(user_id: uid, company_id: company_id)
      else
        true
      end

      render plain: "Forbidden", status: :forbidden unless has_access
    end
  end
end


