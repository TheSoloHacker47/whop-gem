require_relative "dsl"

Whop::DSL.define do
  resource :access do
    graphql :check_if_user_has_access_to_experience, operation: "checkIfUserHasAccessToExperience", args: %i[userId experienceId]
    graphql :check_if_user_has_access_to_access_pass, operation: "checkIfUserHasAccessToAccessPass", args: %i[userId accessPassId]
    graphql :check_if_user_has_access_to_company, operation: "checkIfUserHasAccessToCompany", args: %i[userId companyId]
  end

  resource :users do
    rest_get :get, path: "/v5/users/:userId", args: %i[userId]
    # GraphQL user helpers (mirror TS SDK)
    graphql :get_current_user, operation: "getCurrentUser", args: []
    graphql :get_user, operation: "getUser", args: %i[userId]
    graphql :get_user_ledger_account, operation: "getUserLedgerAccount", args: []
    graphql :list_user_socials, operation: "listUserSocials", args: %i[userId after before first last]
    graphql :ban_user, operation: "banUser", args: %i[input]
    graphql :unban_user, operation: "unbanUser", args: %i[input]
    graphql :mute_user, operation: "muteUser", args: %i[input]
    graphql :unmute_user, operation: "unmuteUser", args: %i[input]
  end

  resource :experiences do
    rest_get :get, path: "/v5/experiences/:experienceId", args: %i[experienceId]
    graphql :list_experiences, operation: "listExperiences", args: %i[first after]
    graphql :get_experience, operation: "getExperience", args: %i[experienceId]
  end

  resource :companies do
    rest_get :get, path: "/v5/companies/:companyId", args: %i[companyId]
    graphql :get_company, operation: "getCompany", args: %i[companyId]
    graphql :get_company_ledger_account, operation: "getCompanyLedgerAccount", args: %i[companyId]
    graphql :list_company_members, operation: "listMembers", args: %i[companyId first after]
  end

  resource :payments do
    graphql :create_checkout_session, operation: "createCheckoutSession", args: %i[input]
    graphql :charge_user, operation: "chargeUser", args: %i[input]
    graphql :pay_user, operation: "payUser", args: %i[input]
    graphql :list_receipts_for_company, operation: "listReceiptsForCompany", args: %i[companyId first after filter]
  end

  resource :invoices do
    graphql :create_invoice, operation: "createInvoice", args: %i[input]
    graphql :get_invoice, operation: "getInvoice", args: %i[invoiceId companyId]
    graphql :list_invoices, operation: "listInvoices", args: %i[companyId after before first last]
  end

  resource :promo_codes do
    graphql :create_promo_code, operation: "createPromoCode", args: %i[input]
    graphql :delete_promo_code, operation: "deletePromoCode", args: %i[input]
    graphql :get_promo_code, operation: "getPromoCode", args: %i[code planId]
    graphql :list_promo_codes, operation: "listPromoCodes", args: %i[first after]
  end

  resource :apps do
    graphql :create_app, operation: "createApp", args: %i[input]
    graphql :update_app, operation: "updateApp", args: %i[input]
    graphql :get_app, operation: "getApp", args: %i[appId]
    graphql :list_apps, operation: "listApps", args: %i[first after]
    graphql :create_app_build, operation: "createAppBuild", args: %i[input]
    graphql :promote_app_build, operation: "promoteAppBuild", args: %i[input]
    graphql :unassign_app_build, operation: "unassignAppBuild", args: %i[input]
    graphql :update_app_permissions, operation: "updateAppPermissions", args: %i[input]
  end

  resource :webhooks do
    graphql :create_webhook, operation: "createWebhook", args: %i[input]
    graphql :update_webhook, operation: "updateWebhook", args: %i[input]
    graphql :test_webhook, operation: "testWebhook", args: %i[input]
    graphql :delete_webhook, operation: "deleteWebhook", args: %i[input]
    graphql :get_webhook, operation: "getWebhook", args: %i[id]
    graphql :list_webhooks, operation: "listWebhooks", args: %i[first after]
  end

  resource :messages do
    graphql :find_or_create_chat, operation: "findOrCreateChat", args: %i[input]
    graphql :send_message_to_chat, operation: "sendMessageToChat", args: %i[experienceId message attachments]
    graphql :send_direct_message_to_user, operation: "sendDirectMessageToUser", args: %i[input]
    graphql :list_direct_message_conversations, operation: "listDirectMessageConversations", args: %i[first after]
    graphql :list_messages_from_chat, operation: "listMessagesFromChat", args: %i[experienceId first after]
  end

  resource :notifications do
    graphql :send_push_notification, operation: "sendPushNotification", args: %i[input]
  end
end


