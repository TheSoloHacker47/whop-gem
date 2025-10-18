# Whop iframe checkout integration: exact code changes

This document captures the precise code changes that were applied to make Whop’s iframe checkout work in this Rails app, including CSP updates that allow the embed and SDK network activity.

Symptoms that triggered the fix:
- Client error: “iframe sdk unavailable” when clicking Buy in the purchase modal, despite the backend returning a valid checkout session id.
- Root cause: the page loaded the wrong SDK and never initialized a global iframe SDK instance available to Stimulus.

Files changed:
- [app/views/layouts/application.html.erb](app/views/layouts/application.html.erb)
- [app/javascript/application.js](app/javascript/application.js)
- [config/importmap.rb](config/importmap.rb)
- [config/initializers/content_security_policy.rb](config/initializers/content_security_policy.rb)

Related (unchanged, but important for flow):
- [app/javascript/controllers/purchase_modal_controller.js](app/javascript/controllers/purchase_modal_controller.js)
- [app/controllers/api/charges_controller.rb](app/controllers/api/charges_controller.rb)
- [config/initializers/whop.rb](config/initializers/whop.rb)

--------------------------------------------------------------------------------

1) app/views/layouts/application.html.erb

- Removed legacy script that pointed to the wrong package:
  <script src="https://unpkg.com/@whop/iframe-sdk@latest" nonce="..."></script>

- Added the correct Whop iframe SDK UMD script, plus a safe inline initializer that exposes window.iframeSdk:
```html
<!-- Whop iframe SDK (UMD) -->
<script src="https://unpkg.com/@whop/iframe@latest" nonce="<%= content_security_policy_nonce %>"></script>
<!-- Initialize global iframeSdk for Stimulus controllers -->
<script nonce="<%= content_security_policy_nonce %>">
  (function () {
    try {
      var g = window;
      var create =
        (g.WhopIframe && g.WhopIframe.createSdk) ||
        (g.WhopIframeSdk && g.WhopIframeSdk.createSdk) ||
        g.createWhopIframeSdk ||
        g.createSdk;

      if (create && !g.iframeSdk) {
        var appId = "<%= ENV['WHOP_APP_ID'] %>" || (document.body && document.body.dataset && document.body.dataset.whopAppId) || "";
        if (appId) {
          g.iframeSdk = create({ appId: appId });
          console.info("[WHOP] iframeSdk initialized", {
            hasInAppPurchase: typeof g.iframeSdk?.inAppPurchase === "function"
          });
        } else {
          console.warn("[WHOP] missing WHOP_APP_ID; iframeSdk not initialized");
        }
      } else {
        console.warn("[WHOP] iframe sdk create function not found", {
          WhopIframe: !!g.WhopIframe,
          WhopIframeSdk: !!g.WhopIframeSdk
        });
      }
    } catch (e) {
      console.error("[WHOP] sdk init error", e);
    }
  })();
</script>
```

- Ensured the WHOP_APP_ID is available to client scripts via a data attribute on body:
```html
<body data-whop-app-id="<%= ENV['WHOP_APP_ID'] %>">
  <!-- ... -->
</body>
```

Why: Stimulus’ purchase modal calls window.iframeSdk.inAppPurchase(...). Without a globally initialized SDK, the call fails. The UMD + inline init guarantees presence early on initial page load.

--------------------------------------------------------------------------------

2) app/javascript/application.js

- Added an ESM/importmap fallback to ensure the SDK initializes during Turbo navigation and when module load order varies.

Final content added to the entry (imports + DOM-ready/Turbo hook):
```js
// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import { createSdk } from "whop_iframe"

function initWhopSdk() {
  try {
    if (window.iframeSdk) return;

    const appId = document.body?.dataset?.whopAppId || "";
    if (!appId) {
      console.warn("[WHOP] missing data-whop-app-id on body; iframeSdk not initialized");
      return;
    }

    if (typeof createSdk === "function") {
      window.iframeSdk = createSdk({ appId });
      console.info("[WHOP] iframeSdk initialized (importmap/domready)", {
        hasInAppPurchase: typeof window.iframeSdk?.inAppPurchase === "function"
      });
    } else {
      console.warn("[WHOP] createSdk not available yet, will retry");
      setTimeout(initWhopSdk, 300);
    }
  } catch (e) {
    console.error("[WHOP] importmap sdk init error", e);
  }
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", initWhopSdk);
} else {
  initWhopSdk();
}
// Re-init on Turbo navigation
window.addEventListener("turbo:load", initWhopSdk);
```

Why: Turbo keeps the page alive across navigations. If the UMD script executed before body was available or across navigation boundaries, this fallback guarantees window.iframeSdk exists by the time the modal uses it.

--------------------------------------------------------------------------------

3) config/importmap.rb

- Added a pin for @whop/iframe via esm.sh, enabling the ESM fallback import used in the entry:
```ruby
pin "whop_iframe", to: "https://esm.sh/@whop/iframe@latest"
```

Full importmap after change (excerpt):
```ruby
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "whop_iframe", to: "https://esm.sh/@whop/iframe@latest"
pin_all_from "app/javascript/controllers", under: "controllers"
```

Why: This lets us import { createSdk } from "whop_iframe" in application.js without bundling, using importmap.

--------------------------------------------------------------------------------

4) config/initializers/content_security_policy.rb

- Expanded CSP to allow the Whop iframe and SDK network activity. Notable additions:
  - script_src includes unpkg.com (UMD) and esm.sh (ESM)
  - connect_src includes whop.com and *.whop.com
  - frame_src and frame_ancestors include whop.com and *.whop.com
  - nonce generator for inline scripts

Resulting policy block (highlights shown):
```ruby
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none

    # Scripts: app + unpkg/esm.sh for Whop SDK (UMD + ESM)
    policy.script_src  :self, :https, "https://unpkg.com", "https://esm.sh"

    # Styles
    policy.style_src   :self, :https

    # Network calls (XHR/WebSocket/fetch) to Whop
    policy.connect_src :self, :https, "https://whop.com", "https://*.whop.com"

    # Allow embedding and frames for Whop checkout/iframe
    policy.frame_src   :self, "https://whop.com", "https://*.whop.com"
    policy.frame_ancestors :self, "https://whop.com", "https://*.whop.com"
  end

  # Generate nonces for inline scripts and styles
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w(script-src style-src)

  # config.content_security_policy_report_only = true
end
```

Note: There is also an initializer [config/initializers/whop_iframe.rb](config/initializers/whop_iframe.rb) that adjusts headers and CSP. You may consolidate these into a single initializer to avoid conflicting policies, but it’s not required for functionality.

--------------------------------------------------------------------------------

5) How the modal uses the SDK (reference)

- The Stimulus controller expects a global window.iframeSdk with an inAppPurchase function. After POST /api/charge returns a session, it calls:
```js
await window.iframeSdk.inAppPurchase(sessionOrCheckout)
```
Source: [app/javascript/controllers/purchase_modal_controller.js](app/javascript/controllers/purchase_modal_controller.js)

--------------------------------------------------------------------------------

6) Server-side session creation (reference)

- The backend creates the checkout session via the Whop Ruby gem and returns the normalized shape containing id:
```ruby
session = Whop.api.payments.create_checkout_session(input: input_payload)
normalized = session.is_a?(Hash) ? (session.dig("data", "createCheckoutSession") || session) : session
render json: normalized
```
Source: [app/controllers/api/charges_controller.rb](app/controllers/api/charges_controller.rb)

--------------------------------------------------------------------------------

7) Verify the setup

- Restart Rails so CSP and initializers are active.
- Hard refresh (Cmd+Shift+R).
- Open DevTools Console and click Buy (Subscription or Credits).
- You should see:
  - “[WHOP] iframeSdk initialized … hasInAppPurchase: true”
  - “[PURCHASE_MODAL] calling iframeSdk.inAppPurchase? function”
  - Whop checkout overlay/iframe opens.

--------------------------------------------------------------------------------

8) Notes on console warnings

- Radix Dialog accessibility warnings: originate from components inside the Whop iframe; safe to ignore in dev.
- Apple Pay manifest warnings: expected in dev or when Apple Pay domain isn’t validated; harmless unless you plan to enable Apple Pay in production.
- MetaMask deprecation warning: extension noise, unrelated to Whop checkout.

--------------------------------------------------------------------------------

9) Quick before/after summary

- Before:
  - Script: https://unpkg.com/@whop/iframe-sdk@latest (wrong package)
  - No global SDK initialization on page → window.iframeSdk undefined

- After:
  - Script: https://unpkg.com/@whop/iframe@latest (correct UMD)
  - Inline initializer in layout head creates window.iframeSdk
  - ESM fallback via importmap ensures SDK exists on DOMContentLoaded and turbo:load
  - CSP allows unpkg, esm.sh, and whop domains (scripts, frames, connect)

With these changes, the Whop iframe checkout opens reliably from the purchase modal.