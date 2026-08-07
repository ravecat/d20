## Why

The shared account dialog needs most of the mobile viewport for its longer content, but an edge-to-edge surface no longer reads as a dialog. Mobile players need a small outer reveal like the expanded game window, and the close action must not drift downward when a localized or narrow title wraps.

## What Changes

- Make Register and Login modes nearly fill the available dynamic viewport at the supported mobile breakpoint while retaining a small safe-area-aware outer inset.
- Retain the dialog border, radius, and shadow so the inset surface remains visibly distinct from its backdrop.
- Align the explicit close action to the top of the title row when the title wraps.
- Preserve the common mobile content inset and internal scrolling so short viewports do not hide controls.
- Preserve the existing content-sized, centered dialog surface on wider viewports.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `email-account-login`: Require the shared account dialog to become a near-full-viewport, safe-area-aware inset surface at supported mobile widths while retaining internal scrolling and the existing desktop layout.
- `email-account-registration`: Require Register mode to use the same inset mobile surface, keep every registration action reachable, and keep the close action top-aligned when its title wraps.

## Impact

- Affects the responsive CSS in `assets/js/shared/components/auth_dialog.svelte`, focused browser coverage, and the two existing account-dialog specifications.
- Continues the account outcomes tracked by GitHub issues #21 and #193, both already present in the D20 Project.
- Does not change auth state, focus behavior, routes, form payloads, account or session behavior, dependencies, migrations, deployment, or iframe contracts.
- Rollback restores the edge-to-edge mobile surface and vertically centered title-row controls.
