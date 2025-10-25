# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

### Changed
- Add `Whop.sdk` exposing official REST `WhopSDK::Client` (preferred API layer).
- Controller helpers now use REST SDK: `current_whop_user` and `require_whop_access!` route through `Whop.sdk`.
- `Whop::Access` now uses REST `users.check_access` via SDK (replaces inline GraphQL).
- README and `whop_gem.txt` updated to prefer REST SDK usage.

### Deprecated
- GraphQL methods on `Whop::Client` (`graphql`, `graphql_query`, `graphql_each_page`) now emit deprecation warnings.
- GraphQL-heavy DSL calls under `Whop.api` emit deprecation warnings. Use `Whop.sdk`.

### Added
- Runtime dependency on `whop_sdk`.
- Iframe helper remains: `Whop::IframeHelper#whop_iframe_sdk_tags` renders UMD script + inline init and an ESM fallback (import from esm.sh) with DOMContentLoaded and turbo:load hooks.
- Installer CSP allows unpkg.com, esm.sh, and whop.com domains for scripts, connect, and frames.
