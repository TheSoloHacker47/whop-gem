require "active_support"
require "active_support/core_ext/module/attribute_accessors"

module Whop
  # Base error type for gem
  require_relative "whop/error"
  class Configuration
    attr_accessor :app_id, :api_key, :webhook_secret, :agent_user_id, :company_id, :api_base_url

    def initialize
      @api_base_url = "https://api.whop.com"
    end
  end

  mattr_accessor :_config, instance_writer: false, default: Configuration.new

  def self.configure
    yield _config if block_given?
    _config
  end

  def self.config
    _config
  end

  def self.client
    require_relative "whop/client"
    @_client ||= Whop::Client.new(config)
  end

  def self.api
    require_relative "whop/dsl"
    DSL::ClientProxy.new(client, DSL.registry)
  end
end

# Ensure core client constant is available when requiring the gem
require_relative "whop/client"

if defined?(Rails)
  require_relative "whop/webhooks/engine"
end

# Load default DSL resource mappings
require_relative "whop/dsl_prelude"

# Ensure webhook signature verifier is loaded for controller usage
require_relative "whop/webhooks/signature"

# Load controller helpers so apps can include Whop::ControllerHelpers
require_relative "whop/token"
require_relative "whop/controller_helpers"

# Load access helpers (used by specs and controller helpers)
require_relative "whop/access"


