## Why

The standalone `AuthPanel` was introduced so account forms could be reused by direct auth pages, but those pages have since been removed and the panel now has only one consumer. Keeping a separate public component plus a version counter for remounting obscures the simple dialog lifecycle and creates a thin abstraction with no remaining reuse.

## What Changes

- Move the account form state, markup, and scoped styles into `AuthDialog`.
- Remove the standalone `AuthPanel` component and its Shared public export.
- Replace the numeric panel-version remount with conditional dialog content whose state is discarded when the dialog closes.
- Preserve registration, login, mode switching, flat form-local error handling, accessibility, layout, and server-prompted behavior.
- Add browser coverage proving that closing and reopening the dialog starts with clean account-entry state.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `email-account-login`: Specify that closing the shared account dialog discards unfinished input and transient form state before the next opening.

## Impact

- `assets/js/shared/components/auth_dialog.svelte`, the obsolete `auth_panel.svelte`, and the Shared component public API.
- Focused header browser tests for close and reopen behavior.
- No Phoenix route, controller, Accounts, session, database, dependency, or iframe contract changes.
- Rollback restores the separate panel component and version-key remount without affecting persisted account data.
