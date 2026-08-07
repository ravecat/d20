## Why

The shared account dialog currently places its description and notices outside the internal scroll container. On short mobile viewports, those rows consume fixed space and can leave the longer Login content clipped or awkwardly divided instead of letting the complete dialog body scroll below a stable title row.

## What Changes

- Keep the account dialog title and explicit close action fixed at the top of the surface.
- Make one existing inner container own every row below the title, starting with the account description and continuing through notices, forms, separators, provider choices, results, and the mode switch.
- Let that body scroller span the dialog surface to its inline edges while keeping the title and body content aligned through their own responsive insets.
- Preserve content-sized desktop behavior while allowing the complete body to scroll on constrained viewports.
- Add focused browser coverage for the scroll boundary and fixed title row.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `email-account-login`: Define the shared account dialog body below its title row as one internal scroll region for both Register and Login modes.

## Impact

- Affects markup and component-scoped layout CSS in `assets/js/shared/components/auth_dialog.svelte` plus focused browser coverage in `assets/tests/app/ui/header.browser.test.ts`.
- Continues the shared account outcomes tracked by GitHub issues #21 and #193, both already present in the D20 Project.
- Does not change auth state, focus behavior, routes, payloads, persistence, dependencies, migrations, deployment, session behavior, or iframe contracts.
- Rollback restores the description and notices as fixed rows outside the existing content scroller and restores padding on the outer dialog surface.
