require "rails/generators"

module Whop
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def create_initializer
        template "whop.rb", "config/initializers/whop.rb"
      end

      def mount_engine
        route "mount Whop::Webhooks::Engine => '/whop/webhooks'"
      end

      def create_iframe_initializer
        template "whop_iframe.rb", "config/initializers/whop_iframe.rb"
      end
    end
  end
end


