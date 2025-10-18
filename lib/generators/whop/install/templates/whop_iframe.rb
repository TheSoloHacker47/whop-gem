# Allow Whop to embed this app in an iframe

Rails.application.config.action_dispatch.default_headers.delete('X-Frame-Options')

Rails.application.config.content_security_policy do |policy|
  policy.frame_ancestors :self, "https://whop.com", "https://*.whop.com"
  # Allow Whop iframe SDK (UMD) and ESM fallback
  policy.script_src :self, :https, "https://unpkg.com", "https://esm.sh"
  # Allow network calls to Whop API from the browser as needed
  policy.connect_src :self, :https, "https://whop.com", "https://*.whop.com"
  # Allow embedding Whop frames
  policy.frame_src   :self, "https://whop.com", "https://*.whop.com"
end


