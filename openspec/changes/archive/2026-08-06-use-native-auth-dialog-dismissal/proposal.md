## Why

The shared account dialog currently duplicates browser backdrop hit testing with pointer-coordinate and element-bound calculations. Native modal dialog light dismissal can remove that scripted geometry while preserving the dialog's focus boundary, explicit close action, and CSS-owned backdrop.

## What Changes

- Declare native `closedby="any"` light dismissal on the shared modal account dialog.
- Remove scripted backdrop click handling and dialog-bound calculations.
- Treat backdrop light dismissal as progressive enhancement while retaining Escape and the explicit close action across supported browsers.
- Cover the native dismissal contract in the focused account-dialog browser tests.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `email-account-login`: The shared modal account dialog delegates backdrop light dismissal to the native dialog API without scripted hit testing.
- `email-account-registration`: Register mode receives the same native backdrop dismissal and cross-browser fallback behavior.

## Impact

- Affects `assets/js/shared/components/auth_dialog.svelte`, focused browser coverage, and the two account capability specifications.
- Tracks the shared account work in GitHub issues #21 and #193, both already present in the D20 Project.
- Does not change routes, controllers, account persistence, session security, form payloads, dependencies, migrations, or iframe contracts.
- Rollback restores the previous backdrop click handler and removes the declarative attribute.
