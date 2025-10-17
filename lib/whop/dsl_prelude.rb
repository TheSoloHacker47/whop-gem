require_relative "dsl"

Whop::DSL.define do
  resource :access do
    graphql :check_if_user_has_access_to_experience, operation: "CheckIfUserHasAccessToExperience", args: %i[userId experienceId]
    graphql :check_if_user_has_access_to_access_pass, operation: "CheckIfUserHasAccessToAccessPass", args: %i[userId accessPassId]
    graphql :check_if_user_has_access_to_company, operation: "CheckIfUserHasAccessToCompany", args: %i[userId companyId]
  end

  resource :users do
    rest_get :get, path: "/v5/users/:userId", args: %i[userId]
  end

  resource :experiences do
    rest_get :get, path: "/v5/experiences/:experienceId", args: %i[experienceId]
  end

  resource :companies do
    rest_get :get, path: "/v5/companies/:companyId", args: %i[companyId]
  end
end


