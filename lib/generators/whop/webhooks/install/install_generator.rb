require "rails/generators"

module Whop
  module Webhooks
    module Generators
      class InstallGenerator < Rails::Generators::Base
        def add_route
          route "mount Whop::Webhooks::Engine => '/whop/webhooks'"
        end
      end
    end
  end
end


