## Why

Storybook currently constrains every interactive preview to the named desktop viewport even when a contributor has not chosen a responsive test size. The available canvas is a better inspection default, while deterministic visual coverage should continue selecting its explicit desktop, tablet, and mobile viewports.

## What Changes

- Start the interactive Storybook catalog with no emulated viewport selected, matching the toolbar's Reset viewport state.
- Keep the existing Desktop, Tablet landscape, and Mobile viewport options available for explicit contributor selection.
- Keep each Storybook Vitest project pinned to its existing named viewport so visual references and responsive test behavior do not change.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `storybook-component-catalog`: Make the available canvas the interactive viewport default while retaining explicit viewport selection.
- `storybook-theme-toolbar`: Preserve theme defaults and all unrelated Storybook configuration while distinguishing the removed interactive viewport default from retained test viewport globals.

## Impact

- Affects only `assets/.storybook/preview.ts` and the owning Storybook specifications.
- Does not change dependencies, generated visual references, production assets, Phoenix runtime behavior, session contracts, iframe module contracts, or database state.
- Rollback restores the preview-level desktop viewport global.
