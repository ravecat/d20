## Context

The developers action currently assigns `page_title` before rendering the Inertia component, while `developers.svelte` independently declares the same title with `<svelte:head>`. The duplicated value crosses the Phoenix and Svelte boundary without being needed as page data.

## Goals / Non-Goals

**Goals:**

- Keep the developers page title next to the page content that owns it.
- Remove the redundant controller assign and its controller-level expectation.
- Preserve the visible title after the Svelte page renders.

**Non-Goals:**

- Introduce a shared metadata abstraction or a new Inertia prop.
- Change titles for other pages or alter root-layout fallback behavior.
- Change routes, game/session runtime behavior, or public AsyncAPI contracts.

## Decisions

### Use the existing Svelte head declaration

Keep `<svelte:head><title>For developers</title></svelte:head>` as the source of truth. This uses the page's existing Svelte mechanism and avoids adding a metadata component or direct DOM mutation for one static value.

Alternative: keep the Phoenix assign. Rejected because it preserves the duplicate value and couples client-owned metadata to the controller.

Alternative: pass a dedicated title Inertia prop. Rejected because the title is static page metadata and does not need server data or a new public prop contract.

### Test ownership at the responsible layers

The Phoenix controller test will verify that the developers component renders without expecting `page_title`. The Svelte page test will verify `document.title`, making the behavior observable at the layer that owns it.

## Risks / Trade-offs

- [The root layout fallback can be visible before the client page mounts] -> Accept the existing client-rendered Inertia lifecycle because this change intentionally moves title ownership to the page and does not introduce SSR.
- [Nearby test files contain unrelated in-progress edits] -> Stage only the title-specific hunks and the new OpenSpec change.

## Migration Plan

Deploy the controller and test changes together. No data or runtime migration is required. Roll back by restoring the controller assign and controller assertion.

## Open Questions

None.
