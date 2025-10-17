Whop.configure do |config|
  config.app_id         = ENV["WHOP_APP_ID"]
  config.api_key        = ENV["WHOP_API_KEY"]
  config.webhook_secret = ENV["WHOP_WEBHOOK_SECRET"]
  config.agent_user_id  = ENV["WHOP_AGENT_USER_ID"]
  config.company_id     = ENV["WHOP_COMPANY_ID"]
  # config.api_base_url = "https://api.whop.com"
end


