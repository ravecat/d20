## Context

`assets/js/app/layout.svelte` is the only production consumer of the global `Header` and `Footer`. Both components are application-aware shell UI, but they are exported from the transitional `shared/components` segment alongside broadly consumed components. The current worktree also contains ongoing authentication and shell changes, so the relocation must preserve the exact component contents and avoid expanding into a wider Shared-layer reorganization.

## Goals / Non-Goals

**Goals:**

- Make App ownership of the global header and footer explicit.
- Keep the layout responsible for shell composition while the components retain their focused markup, behavior, and styles.
- Preserve the existing component implementation and test coverage through a file-only ownership change.

**Non-Goals:**

- Reclassifying `AuthDialog`, `AuthPanel`, or other transitional Shared components.
- Changing header, footer, layout, authentication, navigation, or responsive behavior.
- Moving the layout entry itself or changing Inertia bootstrap and page resolution.

## Decisions

### Place shell components in `app/ui`

Move `header.svelte` and `footer.svelte` into `assets/js/app/ui`. App is the highest FSD layer and owns the one global Inertia layout that composes these components. A `widgets/header` or `widgets/footer` slice would imply an independently reused composite boundary that the codebase does not currently have.

The alternative of inlining both components into `layout.svelte` was rejected because ownership and file boundaries are separate concerns: the layout owns composition, while each component still contains enough markup and styling to justify a focused file.

### Expose an App UI segment entry point

Add `app/ui/index.ts` and have the layout import `Header` and `Footer` from that local segment API. This gives the App UI segment one explicit boundary and avoids exposing App-specific UI through the lower Shared layer.

Direct file imports would also be legal inside App, but a segment entry point keeps the layout and ownership-focused tests independent of the component filenames.

### Preserve component contents during relocation

Relocate the current worktree versions without editing their markup or styles. Update the header's relative account-dialog import to use the existing Shared component public API, keep its compatible two-value mode type local because plain `tsc` cannot re-export named types from the project's `*.svelte` declaration, remove only the obsolete header and footer exports, and update the layout and ownership-focused test import boundary.

## Risks / Trade-offs

- [The worktree contains uncommitted changes in every moved file] -> Relocate the current file contents exactly and inspect the resulting diff so staged and unstaged user work is not discarded.
- [The header test imports the old Shared file directly] -> Relocate the test under the mirrored App UI test path, consume the App UI entry point, and run the targeted layout and header suites.
- [The remaining `shared/components` segment is still transitional] -> Keep that broader reclassification out of scope and track it through later focused changes.

## Migration Plan

1. Create the App UI segment and relocate the current header and footer files into it.
2. Add its local public API, update the App layout import and header Shared dependency, and remove the old Shared exports.
3. Relocate the ownership-focused header test, then run focused and broader frontend validation.
4. Roll back by restoring the two files and exports under `shared/components` and reverting the layout and test imports.

## Open Questions

None.
