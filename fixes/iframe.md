Proposed gem updates to make the iframe helper robust and self-contained

1) Replace the helper implementation
File: [ruby.module()](lib/whop/iframe_helper.rb:1)
Drop-in replacement for whop_iframe_sdk_tags that:
- Loads known global builds from two CDNs (jsDelivr + unpkg) to guarantee a global in most environments.
- Adds an ESM shim fallback that re-exports createSdk as a global if the globals aren’t provided.
- Waits for the Whop postMessage handshake ("whop:ready") when embedded.
- Initializes window.iframeSdk using app_id from method arg, ENV, Whop.config, or <body data-whop-app-id>.
- Emits diagnostics logs and exposes a __whopIframeReadyPromise for consumers that wish to await readiness.

Content:
```ruby
# lib/whop/iframe_helper.rb
require "erb"

module Whop
  module IframeHelper
    # Renders the Whop iframe SDK tags and initializes a global window.iframeSdk instance.
    # It uses a robust initialization flow that:
    # - Loads both global builds (jsDelivr and unpkg) to ensure a global createSdk is available
    # - Injects an ESM shim as a fallback that provides createSdk if globals are missing
    # - Waits for the "whop:ready" postMessage event when embedded before creating the SDK
    #
    # Usage in layout head:
    #   <%= extend(Whop::IframeHelper) && whop_iframe_sdk_tags %>
    #
    # Optional body attribute if you don't wish to expose ENV on the server:
    #   <body data-whop-app-id="...">
    #
    # CSP: Ensure your policy allows:
    # - script_src: https://unpkg.com https://cdn.jsdelivr.net https://esm.sh
    # - connect_src: https://whop.com https://*.whop.com
    # - frame_src + frame_ancestors: https://whop.com https://*.whop.com
    def whop_iframe_sdk_tags(app_id: nil, nonce: nil)
      resolved_app_id = app_id || ENV["WHOP_APP_ID"] || (Whop.config.app_id rescue nil) || ""

      begin
        nonce ||= respond_to?(:content_security_policy_nonce) ? content_security_policy_nonce : nil
      rescue StandardError
      end
      nonce_attr = nonce ? " nonce=\"#{ERB::Util.html_escape(nonce)}\"" : ""

      # Inline initializer with retries + iframe handshake
      init = <<~JS
        (function () {
          var MAX_TRIES = 60;
          var DELAY_MS = 200;
          var __WHOP_NONCE = #{nonce ? ERB::Util.html_escape(nonce).inspect : '""'};

          function getCreate() {
            var g = window;
            var cand =
              (g.WhopIframe && (g.WhopIframe.createSdk || g.WhopIframe.create)) ||
              (g.WhopIframeSdk && (g.WhopIframeSdk.createSdk || g.WhopIframeSdk.create)) ||
              g.createWhopIframeSdk ||
              g.createSdk ||
              null;
            try {
              console.info("[WHOP] getCreate candidates", {
                hasWhopIframe: !!g.WhopIframe,
                hasWhopIframeCreateSdk: !!(g.WhopIframe && g.WhopIframe.createSdk),
                hasWhopIframeCreate: !!(g.WhopIframe && g.WhopIframe.create),
                hasWhopIframeSdk: !!g.WhopIframeSdk,
                hasWhopIframeSdkCreateSdk: !!(g.WhopIframeSdk && g.WhopIframeSdk.createSdk),
                hasWhopIframeSdkCreate: !!(g.WhopIframeSdk && g.WhopIframeSdk.create),
                hasCreateWhopIframeSdk: !!g.createWhopIframeSdk,
                hasCreateSdk: !!g.createSdk
              });
            } catch (_) {}
            return cand;
          }

          function injectFallbackScript() {
            try {
              if (!document.getElementById("whop-iframe-fallback")) {
                var s = document.createElement("script");
                s.id = "whop-iframe-fallback";
                s.async = true;
                if (__WHOP_NONCE) try { s.setAttribute("nonce", __WHOP_NONCE); } catch (_) {}
                s.src = "https://unpkg.com/@whop/iframe@latest/dist/index.global.js";
                s.onload = function () {
                  try { console.info("[WHOP] fallback global script loaded"); } catch (_) {}
                };
                document.head.appendChild(s);
                try { console.info("[WHOP] appended fallback global script"); } catch (_) {}
              }
            } catch (e) {
              try { console.warn("[WHOP] failed to append fallback global script", e); } catch (_) {}
            }
          }

          function injectEsmShim() {
            try {
              if (!document.getElementById("whop-iframe-esm-shim-inline")) {
                var s = document.createElement("script");
                s.id = "whop-iframe-esm-shim-inline";
                s.type = "module";
                if (__WHOP_NONCE) try { s.setAttribute("nonce", __WHOP_NONCE); } catch (_) {}
                s.textContent = [
                  'import { createSdk as _createSdk } from "https://esm.sh/@whop/iframe@latest";',
                  'window.WhopIframe = window.WhopIframe || {};',
                  'window.WhopIframe.createSdk = window.WhopIframe.createSdk || _createSdk;',
                  'window.createWhopIframeSdk = window.createWhopIframeSdk || _createSdk;',
                  'window.createSdk = window.createSdk || _createSdk;',
                  'console.info("[WHOP] ESM shim loaded");'
                ].join("\\n");
                document.head.appendChild(s);
                try { console.info("[WHOP] appended ESM shim module"); } catch (_) {}
              }
            } catch (e) {
              try { console.warn("[WHOP] failed to append ESM shim module", e); } catch (_) {}
            }
          }

          function whenWhopReady(cb) {
            if (window === window.parent) return cb(); // not embedded, proceed
            var ready = false;
            function onMsg(ev) {
              try {
                if (ev && ev.data && ev.data.type === "whop:ready") {
                  ready = true; window.removeEventListener("message", onMsg); cb();
                }
              } catch(_) {}
            }
            window.addEventListener("message", onMsg, { once: true });
            setTimeout(function () { if (!ready) cb(); }, 2000);
          }

          function init(attempt) {
            attempt = attempt || 0;
            try {
              if (window.iframeSdk) return;
              var create = getCreate();
              if (!create) {
                if (attempt === 0) {
                  injectFallbackScript();
                  injectEsmShim();
                }
                if (attempt < MAX_TRIES) {
                  return setTimeout(function () { init(attempt + 1); }, DELAY_MS);
                } else {
                  console.warn("[WHOP] createSdk not available after retries");
                  return;
                }
              }

              var appId = #{resolved_app_id.to_s.strip.empty? ? '""' : ERB::Util.html_escape(resolved_app_id).inspect};
              if (!appId) {
                var body = document.body;
                appId = (body && body.dataset && body.dataset.whopAppId) || "";
              }
              if (!appId) {
                console.warn("[WHOP] missing WHOP_APP_ID; iframeSdk not initialized");
                return;
              }

              whenWhopReady(function () {
                try {
                  if (!window.iframeSdk) window.iframeSdk = create({ appId: appId });
                  try {
                    console.info("[WHOP] iframeSdk initialized", {
                      hasInAppPurchase: typeof window.iframeSdk?.inAppPurchase === "function"
                    });
                  } catch (_) {}

                  try {
                    window.__whopIframeReadyPromise = window.__whopIframeReadyPromise || new Promise(function (resolve) {
                      (function waitReady(attempt){
                        if (window.iframeSdk && typeof window.iframeSdk.inAppPurchase === "function") return resolve();
                        setTimeout(function(){ waitReady((attempt||0)+1); }, 100);
                      })();
                    });
                  } catch(_) {}
                } catch (e) {
                  console.error("[WHOP] sdk init error", e);
                }
              });
            } catch (e) {
              console.error("[WHOP] iframe sdk init error", e);
            }
          }

          if (document.readyState === "loading") {
            document.addEventListener("DOMContentLoaded", function () { init(0); });
            window.addEventListener("load", function () { init(0); });
          } else {
            init(0);
          }
        })();
      JS

      html = %Q(
        <script src="https://cdn.jsdelivr.net/npm/@whop/iframe@latest/dist/index.global.js"#{nonce_attr}></script>
        <script src="https://unpkg.com/@whop/iframe@latest/dist/index.global.js"#{nonce_attr}></script>
        <script type="module"#{nonce_attr}>
          import { createSdk as _createSdk } from "https://esm.sh/@whop/iframe@latest";
          window.WhopIframe = window.WhopIframe || {};
          window.WhopIframe.createSdk = window.WhopIframe.createSdk || _createSdk;
          window.createWhopIframeSdk = window.createWhopIframeSdk || _createSdk;
          window.createSdk = window.createSdk || _createSdk;
          try { console.info("[WHOP] ESM shim loaded"); } catch (_) {}
        </script>
        <script#{nonce_attr}>#{init.strip}</script>
      ).strip
      html.respond_to?(:html_safe) ? html.html_safe : html
    end
  end
end
```

2) Optionally auto-include the helper in Rails views
So apps don’t need to call extend(...), you can load and include the helper automatically.

Add to [ruby.module()](lib/whop.rb:1) after existing requires:
```ruby
# lib/whop.rb
require_relative "whop/iframe_helper"

if defined?(Rails)
  ActiveSupport.on_load(:action_view) { include Whop::IframeHelper }
end
```

3) Update the installer CSP template
File: [ruby.module()](lib/generators/whop/install/templates/whop_iframe.rb:1)
Ensure script/connect/frame sources match what the helper needs:
- script_src: "https://unpkg.com", "https://cdn.jsdelivr.net", "https://esm.sh"
- frame_src + frame_ancestors: "https://whop.com", "https://*.whop.com"
- connect_src: "https://whop.com", "https://*.whop.com"

Example:
```ruby
# config/initializers/whop_iframe.rb (installer template)
Rails.application.config.content_security_policy do |policy|
  policy.script_src  :self, :https, "https://unpkg.com", "https://cdn.jsdelivr.net", "https://esm.sh"
  policy.connect_src :self, :https, "https://whop.com", "https://*.whop.com"
  policy.frame_src   :self, "https://whop.com", "https://*.whop.com"
  policy.frame_ancestors :self, "https://whop.com", "https://*.whop.com"
end

Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
Rails.application.config.content_security_policy_nonce_directives = %w(script-src style-src)
```

4) README changes
File: [ruby.module()](README.md:1)
- Document the one-liner usage:
```erb
<%= whop_iframe_sdk_tags %>
```
- Or if you don’t auto-include helper in views:
```erb
<%= extend(Whop::IframeHelper) && whop_iframe_sdk_tags %>
```
- Mention optional:
```html
<body data-whop-app-id="YOUR_APP_ID">
```
- Add note the helper waits for the iframe handshake in embedded contexts and exposes window.__whopIframeReadyPromise for consumers who want to await readiness.

5) Version bump
- Update gem version (e.g., 1.0.5) and CHANGELOG to reflect:
  - Robust iframe SDK initialization
  - Dual-CDN globals + ESM fallback
  - Handshake-aware initialization
  - CSP installer template updated
  - Optional auto-inclusion of IframeHelper into ActionView

Why this matches the working setup
- Your local override proved that:
  - Using the explicit global builds (index.global.js) and/or an ESM shim is required for createSdk to appear reliably.
  - Waiting for the embedded “whop:ready” handshake avoids calling inAppPurchase too early.
- The changes above port exactly that behavior into the gem, so apps only need the helper call in their layout head and correct CSP, avoiding the “createSdk not available” and “iframe sdk unavailable” states.

Rollout plan
- Implement the code in the gem
- Bump version and release
- In apps, remove ad hoc overrides and just use:
  - [erb.tag()](app/views/layouts/application.html.erb:23) <%= whop_iframe_sdk_tags %>
  - Ensure WHOP_APP_ID is set or use <body data-whop-app-id="...">
  - Confirm CSP initializer includes unpkg, jsDelivr, esm.sh, and Whop domains