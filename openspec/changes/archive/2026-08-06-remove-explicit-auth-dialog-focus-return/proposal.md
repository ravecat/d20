## Why

The shared account dialog keeps a live reference to the header Register button solely to force focus back to that element on close. This caller-specific DOM coupling is not currently needed and makes the dialog API and header state more complex than the account flow requires.

## What Changes

- Remove the header's reactive Register-button element reference and `bind:this` directive.
- Remove the `returnFocusTo` prop and explicit post-close `.focus()` call from the shared account dialog.
- Let the native modal dialog and browser determine focus after close while preserving focus entry, modal focus containment, Escape, native light dismissal, and the explicit close action.
- Update focused browser coverage so it no longer treats application-forced focus restoration as an account-dialog contract.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `email-account-login`: Remove the application-level requirement to restore focus to the invoking header action after the shared dialog closes.
- `email-account-registration`: Remove the application-level requirement to restore focus to the Register trigger after the registration dialog closes.

## Impact

- Affects `assets/js/app/ui/header.svelte`, `assets/js/shared/components/auth_dialog.svelte`, and the focused header browser test.
- Tracks shared account work in GitHub issues #21 and #193, both already present in the D20 Project.
- Does not change account forms, routes, controllers, persistence, session security, dependencies, migrations, or iframe contracts.
- Rollback restores the element prop, button binding, explicit focus call, and corresponding assertions.
