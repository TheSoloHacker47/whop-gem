module Whop
  module Webhooks
    class WebhooksController < ActionController::API
      # Validates the webhook payload using the configured secret.
      def receive
        secret = ENV["WHOP_WEBHOOK_SECRET"] || Whop.config.webhook_secret
        unless secret
          render plain: "Not configured", status: :service_unavailable and return
        end

        payload = request.raw_post
        provided_sig = request.get_header("HTTP_X_WHOP_SIGNATURE") || request.headers["X-Whop-Signature"] || request.headers["x-whop-signature"]
        expected_sig = Whop::Webhooks::Signature.compute(secret, payload)
        if defined?(Rails) && Rails.env.development?
          Rails.logger.info("[Whop] webhook sig expected=sha256=#{expected_sig} provided=#{provided_sig}")
        end
        unless Whop::Webhooks::Signature.valid?(secret, payload, provided_sig)
          render plain: "Invalid signature", status: :unauthorized and return
        end

        event = JSON.parse(payload) rescue nil
        if event.nil? || !event.is_a?(Hash) || event["action"].nil?
          render plain: "Bad Request", status: :bad_request and return
        end

        enqueue_handler(event)
        head :ok
      end

      private

      def enqueue_handler(event)
        action = event["action"].to_s
        job_class_name = action.tr(".", "_").camelize
        namespaced = "Whop::#{job_class_name}Job"
        job_class = namespaced.safe_constantize
        if job_class
          job_class.perform_later(event)
        end
      end
    end
  end
end


