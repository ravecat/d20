## Why

Players currently see Apple as an unavailable account method even though D20 already has the provider-independent identity persistence needed to resolve an Apple account. Apple authentication needs a dedicated secure web flow because scoped authorization returns by cross-site POST, discloses profile data differently from other providers, and must preserve D20's local account and session boundaries.

## What Changes

- Add credential-derived Sign in with Apple runtime availability backed by an operator-supplied Services ID, Team ID, Key ID, private key, and callback URL, with Ueberauth generating the client-secret JWT inside the Apple provider boundary.
- Add explicit Apple request, POST callback, provider-neutral registration-completion, and account-linking flows under the shared `D20Web.Auth` namespace with Ueberauth state and Apple ID-token nonce validation.
- Register unknown Apple identities atomically with a confirmed D20 email, required local username, and durable Apple identity without silently merging on email.
- Authenticate returning Apple identities through the existing D20 session boundary and rotate the browser session before returning to a validated local path.
- Let a recently authenticated player explicitly link an unowned Apple identity from Account Settings without changing identity ownership on conflicts, carrying callback feedback through provider-owned encrypted state rather than query parameters or settings-controller branches.
- Expose Apple availability and link state alongside Google in the Svelte authentication and settings surfaces while leaving every unavailable provider noninteractive.
- Standardize provider action copy so registration uses `Sign up with <provider>` and login uses `Sign in with <provider>` across Google, Facebook, Apple, and Discord.
- Present successful email registration and magic-link requests as informational inline notifications, appending the local mailbox link only to those results when local delivery is available instead of keeping development guidance permanently visible.
- Refine the shared inline-notification text rhythm so multi-line messages align their trailing symbol with the first line, use improved wrapping where supported, and keep short linked labels intact.
- Organize deterministic Storybook authentication scenarios under `Sign In` and `Sign Up`, covering the production authentication dialog, Magic Link login confirmation, the distinct Magic Link and auth-provider registration-completion states, and Account Settings while replacing live Inertia form submissions and keeping the desktop addon panel visible to the right of the story canvas.
- Treat deployment of the complete runtime credential set as the operator-owned enablement decision after Services ID, private relay, exact callback, and staging verification are complete.

## Capabilities

### New Capabilities

- `apple-account-authentication`: Secure Apple configuration, authorization, identity normalization, returning login, registration completion, explicit linking, failure handling, and release gating.

### Modified Capabilities

- `email-account-registration`: Enable the Apple choice only when runtime configuration makes the provider available, route unknown identities through local username completion, and keep local mailbox guidance contextual to successful email registration.
- `email-account-login`: Expose provider availability in the shared authentication object, enable returning Apple sign-in through full-document navigation, and keep local mailbox guidance contextual to successful magic-link requests.
- `storybook-component-catalog`: Organize the affected authentication surfaces by user workflow and make their meaningful dialog, confirmation, completion, and account states directly inspectable through typed, backend-independent stories with the desktop addon panel visible beside them.

## Impact

- Dependencies: adds pinned-compatible `ueberauth` and `ueberauth_apple` packages and their reviewed OAuth/JWT transitive dependencies.
- Backend: changes runtime configuration, routes, Accounts registration behavior, `D20Web.Auth` shared props, an Apple adapter/controller below the shared auth namespace, and focused tests.
- Frontend: changes the shared auth dialog, Account Settings, and shared Inertia prop types while reusing the provider-neutral registration-completion page introduced by Google authentication; adds Storybook-only form isolation, workflow-grouped authentication stories, and manager layout configuration for the affected account surfaces.
- Database and public game contracts: no migration and no iframe, channel, or AsyncAPI change; existing `users` and `user_identities` constraints remain authoritative.
- Sessions: successful Apple login uses existing D20 token creation and session renewal; the global D20 cookie keeps its current SameSite policy while one short-lived encrypted Apple flow cookie changes from the callback-required cross-site policy to the stricter same-site registration policy as the flow advances.
- Rollback: remove the Apple runtime credential set to stop new requests while preserving existing users and identity links, then remove the provider web/configuration code and dependencies if a code rollback is required.
