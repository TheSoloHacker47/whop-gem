require "rails/generators"

module Whop
  module Scaffold
    module Generators
      class ExperienceGenerator < Rails::Generators::Base
        argument :experience_id, type: :string, required: false, default: nil, desc: "(optional) Whop Experience ID (not required)"
        source_root File.expand_path("templates", __dir__)

        def create_controller
          template "experiences_controller.rb", "app/controllers/experiences_controller.rb"
        end

        def add_route
          route "get '/experiences/:experienceId', to: 'experiences#show', as: :experience"
        end

        def create_view
          template "show.html.erb", "app/views/experiences/show.html.erb"
        end
      end
    end
  end
end


