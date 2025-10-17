# whop

Build Whop-embedded apps on Rails. This gem mirrors the official Next.js template: verify Whop user tokens, gate access to experiences/companies, handle webhooks, scaffold app views, and call Whop APIs.

## Highlights

- Token verification (server-side JWT) and controller helpers
- Access checks (experience/company/access pass)
- Webhooks engine with signature validation and generators
- Rails generators for app views (Experience/Dashboard/Discover)
- Thin HTTP + GraphQL client, with `with_company`/`with_user` scoping
- Dev conveniences: `whop-dev-user-token`, tolerant webhook verifier

## Requirements

- Ruby 3.2+
- Rails 7.0+ (Rails 8 supported)

## Installation

1) Add to Gemfile and install

```ruby
gem "whop", "~> 1.0"
```

```bash
bundle install
bin/rails g whop:install
```

The installer:
- Creates `config/initializers/whop.rb` (reads env vars)
- Mounts `/whop/webhooks`
- Adds `config/initializers/whop_iframe.rb` so Whop can embed your app (CSP frame-ancestors for `*.whop.com` and removes `X-Frame-Options`).

2) Configure environment variables

- `WHOP_APP_ID`
- `WHOP_API_KEY`
- `WHOP_WEBHOOK_SECRET`
- Optional: `WHOP_AGENT_USER_ID`, `WHOP_COMPANY_ID`

Tip (dev): use dotenv

```bash
echo "WHOP_APP_ID=app_xxx
WHOP_API_KEY=sk_xxx
WHOP_WEBHOOK_SECRET=whsec_xxx
WHOP_AGENT_USER_ID=user_xxx
WHOP_COMPANY_ID=biz_xxx" > .env
```

## App Views (routes that Whop calls)

Set these in the Whop dashboard (Hosting → App Views):

- Experience View: `/experiences/[experienceId]`
- Dashboard View: `/dashboard/[companyId]`
- Discover View: `/discover`

Generate the pages (dynamic IDs provided by Whop; no args needed):

```bash
bin/rails g whop:scaffold:all
# or individually
bin/rails g whop:scaffold:company
bin/rails g whop:scaffold:experience
```

The scaffolds include access gating and safe resource fetches (render even if the REST fetch 404s in early dev).

## Controller helpers

```ruby
class ExperiencesController < ApplicationController
  include Whop::ControllerHelpers
  before_action -> { require_whop_access!(experience_id: params[:experienceId] || params[:id]) }

  def show
    user_id = whop_user_id
    exp_id = params[:experienceId] || params[:id]
    experience = begin
      Whop.client.experiences.get(exp_id)
    rescue StandardError
      { "id" => exp_id }
    end
    render :show, locals: { user_id:, experience: }
  end
end
```

Dev token override (development only): send `whop-dev-user-token` as a header or query param; if it looks like a JWT it will be verified, otherwise it is treated as a raw `user_id`.

## Webhooks

Mounted at `/whop/webhooks`. Signature validation uses `WHOP_WEBHOOK_SECRET`.

Generate a handler job:

```bash
bin/rails g whop:webhooks:handler payment_succeeded
```

Test locally:

```bash
cat > payload.json <<'JSON'
{ "action": "payment.succeeded", "data": { "id": "pay_123", "user_id": "user_123", "final_amount": 1000, "amount_after_fees": 950, "currency": "USD" } }
JSON
SIG=$(ruby -ropenssl -e 's=ENV.fetch("WHOP_WEBHOOK_SECRET"); p=File.read("payload.json"); puts "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", s, p)}"')
curl -i -X POST http://localhost:3000/whop/webhooks \
  -H "Content-Type: application/json" \
  -H "X-Whop-Signature: $SIG" \
  --data-binary @payload.json
```

## Using the client

```ruby
# With app/company context from env
Whop.client.users.get("user_xxx")
Whop.client.experiences.get("exp_xxx")
Whop.client.with_company("biz_xxx").companies.get("biz_xxx")

# GraphQL (persisted operations)
Whop.api.access.check_if_user_has_access_to_experience(userId: "user_xxx", experienceId: "exp_xxx")
```

## Local preview in Whop

- Run Rails: `bin/rails s`
- In Whop dev tools, set environment to `localhost`
- For tunneling, add your ngrok domain to `frame_ancestors` in `whop_iframe.rb`

## Versioning & support

- Add `gem "whop", "~> 1.0"` to stay within v1.x.
- Issues and PRs welcome.

## License

MIT


