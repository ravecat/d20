## Why

The shared account dialog currently duplicates the browser's initial dialog-focus behavior with an imperative helper. Native dialog autofocus can handle initial entry, while the shared mode-switch handler only needs to restore focus after its conditional branch renders.

## What Changes

- Mark the first active account email field for native autofocus when the modal dialog opens.
- Keep post-render focus for an already-open mode change in the shared mode-switch handler.
- Open the native modal once when its conditionally rendered component mounts instead of synchronizing store and DOM open flags.
- Route explicit dismissal through `dialog.close()` and let the native `close` event reset shared auth state and unmount the component.
- Use one auth-store `open` event whose optional prompt initializes either a clean Register session or a prompted Login session.
- Keep password reveal state local to `AuthDialog` instead of storing presentation-only state in the shared auth store.
- Preserve the current active-field focus behavior, email retention, modal containment, and native post-close focus handling.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `email-account-login`: Require the active mode's first email field to receive native focus when the dialog opens and handler-owned post-render focus when an already-open dialog switches modes.
- `email-account-registration`: Require the registration email field to be the native initial-focus target when Register mode opens.

## Impact

- Affects `assets/js/shared/components/auth_dialog.svelte`, `assets/js/shared/stores/auth.ts`, `assets/js/app/ui/header.svelte`, and focused frontend validation.
- Tracks the shared account work in GitHub issues #21 and #193, both already present in the D20 Project.
- Does not change routes, form payloads, account or session behavior, persistence, dependencies, migrations, deployment, or iframe contracts.
- Rollback restores the shared password-visibility event, open-state synchronization effect, and imperative focus helper, then removes the declarative autofocus attributes.
