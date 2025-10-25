module Whop
  # Access helpers using REST via official Whop SDK
  class Access
    def initialize(_client)
      # legacy argument retained for compatibility
    end

    def user_has_access_to_experience?(user_id:, experience_id:)
      check_has_access(resource_id: experience_id, user_id: user_id)
    end

    def user_has_access_to_access_pass?(user_id:, access_pass_id:)
      check_has_access(resource_id: access_pass_id, user_id: user_id)
    end

    def user_has_access_to_company?(user_id:, company_id:)
      check_has_access(resource_id: company_id, user_id: user_id)
    end

    private

    def check_has_access(resource_id:, user_id:)
      resp = Whop.sdk.users.check_access(resource_id, id: user_id)
      if resp.respond_to?(:has_access)
        resp.has_access
      else
        (resp["has_access"] || resp[:has_access]) || false
      end
    rescue StandardError
      false
    end
  end
end


