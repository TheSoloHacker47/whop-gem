# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

- Add extensive GraphQL DSL coverage to match TS SDK key areas:
  - Users, Experiences, Companies
  - Payments (create checkout session, charge user, list receipts, pay user)
  - Invoices (create/get/list)
  - Promo Codes (create/get/list/delete)
  - Apps (create/update/get/list; builds promote/unassign; permissions)
  - Webhooks (create/update/test/delete/get/list)
  - Messages (find/create chat, send messages, list)
  - Notifications (send push notification)
- Add richer error classes and Faraday error mapping:
  - APIConnectionError, APITimeoutError, APIStatusError and specific subclasses
- Add GraphQL auto-pagination helper: Whop::Client#graphql_each_page
- Access checks updated to send inline GraphQL queries when persisted IDs aren’t provided
- Controller helpers:
  - current_whop_user_id, require_whop_user!, current_whop_user
- README updated with examples for new namespaces
 - Iframe helper added: `Whop::IframeHelper#whop_iframe_sdk_tags` renders UMD script + inline init and an ESM fallback (import from esm.sh) with DOMContentLoaded and turbo:load hooks
 - Installer CSP expanded to allow unpkg.com, esm.sh, and whop.com domains for scripts, connect, and frames
