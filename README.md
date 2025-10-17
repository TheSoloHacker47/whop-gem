# whop-rails

Rails 7+ gem to build embedded Whop apps: token verification, access checks, API client, webhooks, and generators. Mirrors Whop's Next.js app template.

## Install

Add to Gemfile:

```ruby
gem "whop-rails", path: "."
```

Generate initializer and mount webhooks:

```bash
bin/rails g whop:install
```

Set env vars:

- `WHOP_APP_ID`
- `WHOP_API_KEY`
- `WHOP_WEBHOOK_SECRET`
- (optional) `WHOP_AGENT_USER_ID`, `WHOP_COMPANY_ID`

## Usage

```ruby
class ExperiencesController < ApplicationController
  include Whop::ControllerHelpers
  before_action -> { require_whop_access!(experience_id: params[:id]) }

  def show
    user_id = whop_user_id
    experience = Whop.client.experiences.get(params[:id])
    render locals: { user_id:, experience: }
  end
end
```

Webhooks:

```bash
bin/rails g whop:webhooks:handler payment_succeeded
# POST /whop/webhooks -> verifies signature, enqueues Whop::PaymentSucceededJob
```

## Example app template

```bash
rails new whop_app -m examples/rails_app/template.rb --skip-jbuilder --skip-action-mailbox --skip-action-text --skip-active-storage
```

## License

MIT


