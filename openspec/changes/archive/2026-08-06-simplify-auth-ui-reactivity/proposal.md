## Why

The auth UI stores values that are either already one-time server data or presentation text selected directly from component inputs. The extra reactive variables obscure ownership, add unnecessary effect work, and move localizable copy away from the markup where it is rendered.

## What Changes

- Remove the `handledPrompt` reactive state from the App header.
- Handle any non-null `page.props.authPrompt` directly when the Inertia prop changes.
- Render the account-dialog title directly in its heading from `reauthenticate` and `mode` instead of constructing an intermediate `$derived` string.
- Preserve the existing Login-mode initialization, dialog opening, prompt copy, reauthentication state, and safe return destination.
- Preserve the existing accessible heading id and all three visible title values.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `email-account-login`: Require mode-specific and reauthentication dialog title copy to be selected at its markup consumption site for localization readiness.
- `email-account-registration`: Apply the same direct-markup title rendering to Register mode.

## Impact

- Affects `assets/js/app/ui/header.svelte`, `assets/js/shared/components/auth_dialog.svelte`, and focused frontend validation.
- Tracks the existing shared account work in GitHub issues #21 and #193, both already present in the D20 Project.
- Does not change Inertia props, routes, controllers, session behavior, account security, dependencies, migrations, or iframe contracts.
- Rollback restores the local reference guard and derived title variable without data or deployment migration.
