require_relative "lib/whop/version"

Gem::Specification.new do |spec|
  spec.name          = "whop"
  spec.version       = Whop::VERSION
  spec.summary       = "Rails integration for Whop Apps: config, token verification, access checks, webhooks, generators."
  spec.description   = "A Rails 7+ gem to build embedded Whop apps. Mirrors Whop's Next.js template: verification, access control, webhooks, and API client with a small meta-programming DSL."
  spec.license       = "MIT"

  spec.authors       = ["Nikhil Nelson"]
  spec.email         = ["thesolohacker47@gmail.com"]

  spec.required_ruby_version = ">= 3.2"
  spec.homepage      = "https://github.com/TheSoloHacker47/whop-gem"
  spec.metadata = {
    "source_code_uri" => "https://github.com/TheSoloHacker47/whop-gem",
    "changelog_uri"   => "https://github.com/TheSoloHacker47/whop-gem/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://gemdocs.org/gems/whop/"
  }

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["lib/**/*", "config/routes.rb", "README.md", "LICENSE", "examples/**/*"]
  end

  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "faraday", "~> 2.9"
  spec.add_dependency "faraday-retry", "~> 2.2"
  spec.add_dependency "activesupport", ">= 7.0", "< 9.0"
  spec.add_dependency "railties",      ">= 7.0", "< 9.0"
  spec.add_dependency "rack",          ">= 2.2", "< 4.0"
  spec.add_dependency "json",          "~> 2.6"
  spec.add_dependency "jwt",           "~> 2.8"
  spec.add_dependency "whop_sdk",      ">= 0.0.1"

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.12"



  
end


