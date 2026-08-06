## Why

D20 already has Phoenix-generated email account creation and magic-link confirmation, but the journey is isolated on a server-rendered page and is absent from the shared Inertia shell. Guests need a clear, recoverable registration entry point that preserves the existing account model, handles application-level delivery failures without crashing, and prepares provider choices without implementing them prematurely.

## What Changes

- Add a guest-only Register action to the shared application header and open registration in an accessible responsive dialog.
- Let a guest create one local account with a valid unique email address and receive the existing confirmation magic link without choosing a password.
- Keep validation, submission, success, and application-level delivery-failure feedback inside the registration mode through Inertia form conventions, including the direct Inertia registration page.
- Show Google, Facebook, Apple, and Discord registration choices as visibly unavailable future options and let existing users switch the same dialog to email sign-in.
- Show the local development mailbox hint only when its dev route and Local mail adapter are both available.
- Preserve case-insensitive email uniqueness under repeated and concurrent submissions and verify that confirmation resolves to the created stable D20 user identity.
- Keep production provider configuration, asynchronous delivery, bounded retries, and delivery telemetry in GitHub issue #38 rather than adding a job system to this change.

## Capabilities

### New Capabilities

- `email-account-registration`: Defines the shared-shell registration entry point, email-only account creation, confirmation handoff, dialog states, duplicate handling, and recoverable application-level delivery failures.

### Modified Capabilities

None.

## Impact

- Phoenix Accounts registration orchestration, the registration controller, browser routing, Inertia form errors, and minimal shared account-flow props.
- The shared Svelte header and shared account-dialog component with focused browser coverage.
- Existing users schema, authentication routes, magic-link confirmation semantics, and game-session contracts remain unchanged.
- No migration, new runtime dependency, iframe protocol change, or production mail-provider configuration is required.
- Rollback restores the former HEEx registration presentation while leaving persisted accounts and tokens unchanged.
