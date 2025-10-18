require "erb"

module Whop
  module IframeHelper
    # Renders the Whop iframe SDK UMD script and a small inline initializer that creates
    # a global window.iframeSdk instance. The initializer uses the provided app_id, or
    # falls back to ENV["WHOP_APP_ID"] / Whop.config.app_id, then finally to
    # document.body.dataset.whopAppId if present.
    #
    # Usage in layout head:
    #   <%= whop_iframe_sdk_tags %>
    # Optionally add <body data-whop-app-id="..."> if you prefer not to expose ENV.
    def whop_iframe_sdk_tags(app_id: nil, nonce: nil)
      resolved_app_id = app_id || ENV["WHOP_APP_ID"] || (Whop.config.app_id rescue nil) || ""
      begin
        # Prefer CSP nonce from Rails if available
        nonce ||= respond_to?(:content_security_policy_nonce) ? content_security_policy_nonce : nil
      rescue StandardError
        # ignore
      end

      nonce_attr = nonce ? " nonce=\"#{ERB::Util.html_escape(nonce)}\"" : ""
      init = <<~JS
        (function () {
          try {
            var g = window;
            var create = (g.WhopIframe && g.WhopIframe.createSdk) ||
                         (g.WhopIframeSdk && g.WhopIframeSdk.createSdk) ||
                         g.createWhopIframeSdk ||
                         g.createSdk;
            if (create && !g.iframeSdk) {
              var appId = #{resolved_app_id.to_s.strip.empty? ? '""' : ERB::Util.html_escape(resolved_app_id).inspect};
              if (!appId) {
                var body = document.body;
                appId = (body && body.dataset && body.dataset.whopAppId) || "";
              }
              if (appId) {
                g.iframeSdk = create({ appId: appId });
              }
            }
          } catch (e) {
            // swallow init errors
          }
        })();
      JS

      html = %Q(<script src="https://unpkg.com/@whop/iframe@latest"#{nonce_attr}></script>\n<script#{nonce_attr}>#{init.strip}</script>)
      html.respond_to?(:html_safe) ? html.html_safe : html
    end
  end
end


