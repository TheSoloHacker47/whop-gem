# frozen_string_literal: true

# Rails application template for a Whop-enabled embedded app.
# Usage:
#   rails new whop_app -m examples/rails_app/template.rb --skip-jbuilder --skip-action-mailbox --skip-action-text --skip-active-storage

say "Adding whop-rails gem..."
append_to_file "Gemfile", <<~RUBY
  
  gem "whop-rails", path: File.expand_path("../../", __dir__)
RUBY

run "bundle install"

say "Installing Whop initializer and webhooks engine..."
generate "whop:install"

env_keys = %w[WHOP_APP_ID WHOP_API_KEY WHOP_WEBHOOK_SECRET]
say "Remember to set ENV: #{env_keys.join(', ')}", :yellow

say "Adding ExperiencesController and route..."
create_file "app/controllers/experiences_controller.rb", <<~RUBY
  class ExperiencesController < ApplicationController
    include Whop::ControllerHelpers
    before_action -> { require_whop_access!(experience_id: params[:id]) }

    def show
      user_id = whop_user_id
      experience = Whop.client.experiences.get(params[:id])
      render :show, locals: { user_id: user_id, experience: experience }
    end
  end
RUBY

create_file "app/views/experiences/show.html.erb", <<~ERB
  <div class="container">
    <h1>Experience</h1>
    <p>User ID: <%= user_id %></p>
    <pre><%= JSON.pretty_generate(experience) %></pre>
  </div>
ERB

route "resources :experiences, only: [:show]"

say "Adding Discover page..."
create_file "app/controllers/discover_controller.rb", <<~RUBY
  class DiscoverController < ApplicationController
    def show; end
  end
RUBY

create_file "app/views/discover/show.html.erb", <<~ERB
  <div class="container">
    <h1>Discover your app</h1>
    <p>Showcase value, link to communities, add referral params.</p>
  </div>
ERB

route "get '/discover', to: 'discover#show'"

say "Generating example webhook handler..."
generate "whop:webhooks:handler", "payment_succeeded"

say "All set. Configure ENV and run: bin/rails server"


