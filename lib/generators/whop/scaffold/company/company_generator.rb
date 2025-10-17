require "rails/generators"

module Whop
  module Scaffold
    module Generators
      class CompanyGenerator < Rails::Generators::Base
        argument :company_id, type: :string, required: false, default: nil, desc: "(optional) Whop Company ID (not required)"
        source_root File.expand_path("templates", __dir__)

        def create_controller
          template "companies_controller.rb", "app/controllers/companies_controller.rb"
        end

        def add_route
          route "get '/dashboard/:companyId', to: 'companies#show', as: :dashboard_company"
        end

        def create_view
          template "show.html.erb", "app/views/companies/show.html.erb"
        end
      end
    end
  end
end


