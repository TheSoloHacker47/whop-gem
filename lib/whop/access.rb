module Whop
  # Access helpers using persisted GraphQL operations per Whop docs
  class Access
    def initialize(client)
      @client = client
    end

    def user_has_access_to_experience?(user_id:, experience_id:)
      data = @client.graphql("CheckIfUserHasAccessToExperience", { userId: user_id, experienceId: experience_id })
      extract_access_boolean(data)
    end

    def user_has_access_to_access_pass?(user_id:, access_pass_id:)
      data = @client.graphql("CheckIfUserHasAccessToAccessPass", { userId: user_id, accessPassId: access_pass_id })
      extract_access_boolean(data)
    end

    def user_has_access_to_company?(user_id:, company_id:)
      data = @client.graphql("CheckIfUserHasAccessToCompany", { userId: user_id, companyId: company_id })
      extract_access_boolean(data)
    end

    private

    def extract_access_boolean(graphql_result)
      if graphql_result.is_a?(Hash)
        data = graphql_result["data"] || graphql_result
        key = %w[hasAccessToExperience hasAccessToAccessPass hasAccessToCompany].find { |k| data.key?(k) rescue false }
        payload = key ? data[key] : data
        return payload["hasAccess"] if payload.is_a?(Hash) && payload.key?("hasAccess")
      end
      !!graphql_result
    end
  end
end


