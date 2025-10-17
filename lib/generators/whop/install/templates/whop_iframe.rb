# Allow Whop to embed this app in an iframe

Rails.application.config.action_dispatch.default_headers.delete('X-Frame-Options')

Rails.application.config.content_security_policy do |policy|
  policy.frame_ancestors :self, "https://whop.com", "https://*.whop.com"
end


