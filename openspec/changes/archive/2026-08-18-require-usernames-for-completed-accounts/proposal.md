## Why

D20 has no production users to migrate, and every supported registration flow already assigns a username before the first authenticated session. Keeping legacy support for authenticated accounts without usernames preserves an unreachable state in Account Settings, public profiles, tests, and Storybook.

## What Changes

- Remove the authenticated one-time username claim API and Account Settings form.
- Treat username as the authenticated display identity instead of falling back to email.
- Remove legacy missing-username fixtures, tests, and the Account Settings Storybook scenario.
- Preserve username selection during Magic Link and provider registration completion, including validation and case-insensitive uniqueness.
- Do not add persistence or authentication guards for a confirmed-without-username state that current product flows cannot create.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `username-account-identity`: Replace legacy username adoption with immutable Account Settings presentation and required username-backed authenticated identity.
- `email-account-registration`: Describe username assignment as part of the reachable registration-completion flow.
- `email-account-login`: Remove the obsolete username settings form from independent Inertia form-state requirements.

## Impact

- Backend: remove `Accounts.claim_username/2`, its settings-controller action, the email display fallback, and legacy fixtures and tests.
- Frontend: make the Account Settings username prop non-nullable and remove the claim form, its tests, and its story.
- Persistence and authentication: retain the existing schema and session boundaries; registration completion remains responsible for assigning username before authentication.
- Specifications: supersede the legacy-account criteria from GitHub issue #192 under follow-up issue #216 and reconcile the active Apple Storybook artifacts that still describe username claiming.
- Rollback: restoring the compatibility paths would re-admit the obsolete Account Settings state; no database rollback is required.
