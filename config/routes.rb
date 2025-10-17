Whop::Webhooks::Engine.routes.draw do
  post "/", to: "webhooks#receive"
end


