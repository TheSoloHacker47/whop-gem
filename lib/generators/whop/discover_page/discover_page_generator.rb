require "rails/generators"

module Whop
  module Generators
    class DiscoverPageGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def create_controller
        template "discover_controller.rb", "app/controllers/discover_controller.rb"
      end

      def add_route
        route "get '/discover', to: 'discover#show'"
      end

      def create_view
        template "show.html.erb", "app/views/discover/show.html.erb"
      end
    end
  end
end


