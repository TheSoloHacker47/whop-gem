require "faraday"
require "json"
require "faraday/retry"

module Whop
  class Error < StandardError; end

  # Thin HTTP client for Whop API + GraphQL with context headers.
  class Client
    attr_reader :config, :on_behalf_of_user_id, :company_id

    def initialize(config, on_behalf_of_user_id: nil, company_id: nil)
      @config = config
      @on_behalf_of_user_id = on_behalf_of_user_id || config.agent_user_id
      @company_id = company_id || config.company_id
    end

    def with_user(user_id)
      self.class.new(config, on_behalf_of_user_id: user_id, company_id: @company_id)
    end

    def with_company(company_id)
      self.class.new(config, on_behalf_of_user_id: @on_behalf_of_user_id, company_id: company_id)
    end

    # REST helpers
    def get(path, params: nil)
      response = connection.get(path) do |req|
        req.params.update(params) if params
      end
      parse_response!(response)
    end

    def post(path, json: nil)
      response = connection.post(path) do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = JSON.generate(json) if json
      end
      parse_response!(response)
    end

    # GraphQL (persisted operations by operationName)
    def graphql(operation_name, variables = {})
      response = Faraday.post("#{config.api_base_url}/public-graphql") do |req|
        apply_common_headers(req.headers)
        req.headers["Content-Type"] = "application/json"
        req.body = JSON.generate({ operationName: operation_name, variables: variables })
      end
      parse_response!(response)
    end

    # Resources
    def users
      @users ||= Resources::Users.new(self)
    end

    def experiences
      @experiences ||= Resources::Experiences.new(self)
    end

    def companies
      @companies ||= Resources::Companies.new(self)
    end

    def access
      require_relative "access"
      @access ||= Access.new(self)
    end

    private

    def connection
      @connection ||= Faraday.new(url: config.api_base_url) do |faraday|
        faraday.request :retry, max: 2, interval: 0.1, backoff_factor: 2
        faraday.response :raise_error
        faraday.adapter Faraday.default_adapter
      end
    end

    def apply_common_headers(headers)
      headers["Authorization"] = "Bearer #{config.api_key}"
      headers["x-on-behalf-of"] = on_behalf_of_user_id if on_behalf_of_user_id
      headers["x-company-id"] = company_id if company_id
    end

    def parse_response!(response)
      body = response.body
      json = parse_body_safely(body)
      if response.status.to_i >= 400
        raise Error, "Whop API error (#{response.status}): #{json.inspect}"
      end
      json
    end

    def parse_body_safely(body)
      return body unless body.is_a?(String) && !body.empty?
      JSON.parse(body)
    rescue JSON::ParserError
      body
    end
  end
end

module Whop
  module Resources
    class Base
      attr_reader :client
      def initialize(client)
        @client = client
      end
    end

    class Users < Base
      def get(user_id)
        client.get("/v5/users/#{user_id}")
      end
    end

    class Experiences < Base
      def get(experience_id)
        client.get("/v5/experiences/#{experience_id}")
      end
    end

    class Companies < Base
      def get(company_id)
        # If the client is already scoped to this company, use the context-aware endpoint
        if client.company_id && client.company_id == company_id
          # Whop v5 exposes a context-aware company endpoint that reads x-company-id
          return client.get("/v5/company")
        end

        # Otherwise, fetch via app-scoped companies endpoint by id
        client.get("/v5/app/companies/#{company_id}")
      end
    end
  end
end

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
      # Attempt to locate the access payload; tolerate schema variants
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


