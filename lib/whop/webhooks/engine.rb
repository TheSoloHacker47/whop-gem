require "rails/engine"

module Whop
  module Webhooks
    class Engine < ::Rails::Engine
      isolate_namespace Whop::Webhooks

      initializer "whop.webhooks.routes" do
        Whop::Webhooks::Engine.routes.draw do
          post "/", to: "webhooks#receive"
        end
      end
    end
  end
end


