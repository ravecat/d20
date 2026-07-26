## Context

The frontend currently has a root Inertia and LiveView bootstrap module, flat Inertia pages, and root-level `components`, `stores`, and `types` directories. The first migration step already established `shared/api` for the connected Phoenix socket and embedded-module transport contracts. The remaining root buckets still obscure the intended App-to-Pages-to-Shared dependency direction.

The FSD custom-architecture migration guide permits an intermediate Shared layer containing technical buckets before those modules are unpacked into page-local code and purpose-based segments. The user explicitly chose this staged relocation to create a navigable structure before deeper refactoring.

The migration must remain compatible with the existing `~/*` Vite and TypeScript alias, the `js/app.js` build and manifest entry, server-provided Inertia page names, Svelte 5 compilation, Vitest module mocking, Phoenix channel topics, and the `@rvct/d20sdk` bootstrap contract.

## Goals / Non-Goals

**Goals:**

- Establish explicit `app`, page-slice, and Shared boundaries under `assets/js`.
- Retain `assets/js/app.js` as a thin framework entry adapter.
- Give every page slice and populated Shared segment a public API.
- Move existing root technical buckets under Shared as a behavior-preserving transitional step.
- Remove legacy import aliases after all consumers use the root alias and new public boundaries.
- Keep runtime behavior and external contracts unchanged.

**Non-Goals:**

- Reclassify workspace or session behavior into Widgets, Features, or Entities.
- Generalize, split, merge, or otherwise redesign Svelte components and stores.
- Make the transitional `shared/components`, `shared/stores`, and `shared/types` segments the final architecture.
- Change page props, component props, store APIs, transport payloads, or test behavior.
- Add Steiger, dependencies, aliases, or build configuration.

## Decisions

### Preserve the existing `shared/api` segment

Move the connected socket from `assets/js/user_socket.js` to `assets/js/shared/api/socket.js` and the embedded-module transport contracts from `assets/js/types/module.ts` to `assets/js/shared/api/module.ts`.

These modules are infrastructure used across concerns and contain no business behavior. A separate `shared/ui` or `shared/lib` segment would be empty, so it will not be created.

This decision was completed in the first implementation stage and remains the transport boundary for the broader migration.

### Expose one segment public API

Add `assets/js/shared/api/index.ts` with a named `socket` runtime export and type-only exports for `ModuleConnection` and `ModuleEntry`. Consumers will import from `~/shared/api` rather than internal Shared files.

Alternative: keep direct imports such as `~/shared/api/socket.js`. Rejected because they expose internal filenames and make later internal changes affect every consumer.

### Preserve the existing root alias

Use the existing `~/*` mapping to address `~/shared/api`. No `~shared` or `@/shared` alias will be added.

Remove the narrower `~actions`, `~components`, `~pages`, `~stores`, and `~types` aliases after their target directories move or are confirmed absent. The root alias already expresses the complete layer path and resolves consistently in TypeScript, Vite, and Vitest.

### Keep `js/app.js` as a thin entry adapter

Move application bootstrap implementation to `assets/js/app/entrypoint.js`. Keep `assets/js/app.js` as a side-effect import of that module so the production input, Phoenix template asset names, and Vite manifest key remain `js/app.js`.

Alternative: change the Vite and Phoenix entry to `js/app/entrypoint.js`. Rejected because the entry name is an established build contract and changing it provides no architectural value.

### Convert flat pages into page slices

Move each page to `assets/js/pages/<page>/ui/<page>.svelte` and add `assets/js/pages/<page>/index.ts` as its public API. The App bootstrap eagerly imports page public APIs and maps the existing server-provided names `home`, `game`, and `developers` to those modules.

Cross-page presentation tests remain in frontend test infrastructure and import pages only through their public APIs.

### Use transitional Shared technical segments

Move the root `components`, `stores`, and `types` directories to `shared/components`, `shared/stores`, and `shared/types`. Add a segment-level `index.ts` for each and update external consumers to import through those public APIs.

This intentionally applies the coarse relocation stage of the FSD custom migration before unpacking Shared. `components` and `types` group modules by technical kind and are not the desired final segment names. Some moved modules are page-specific or domain-aware. The compromise is accepted for this change because it establishes legal dependency direction without combining relocation with behavior and ownership refactoring.

Follow-up changes should move single-page UI and models into their page slices, rename genuinely reusable presentation primitives into `shared/ui`, and form Widgets, Features, or Entities only after reuse and boundaries are demonstrated.

### Treat relocation separately from refactoring

Do not change Svelte props, formatting behavior, stores, channel normalization, component markup, CSS, accessibility names, or test assertions. Internal imports within a moved segment may remain relative; consumers outside a segment use its public API.

## Risks / Trade-offs

- [Public barrel loads the socket for runtime consumers] -> Keep type-only imports erased and use the barrel only for modules that already require the singleton socket.
- [Vitest mocks stop intercepting the socket] -> Update mock specifiers to the public Shared API and preserve the named export shape.
- [Transitional Shared segments contradict final FSD desegmentation] -> Document them as migration scaffolding and defer semantic unpacking to focused follow-up changes.
- [Barrel imports introduce cycles inside Shared] -> Use relative imports between files in the same segment and reserve segment public APIs for external consumers.
- [Page discovery changes when files become nested] -> Resolve only page `index.ts` public APIs and preserve the existing page-name lookup.
- [Moving the bootstrap changes the production asset name] -> Keep the root `js/app.js` adapter and verify the production manifest.
- [Large relocation obscures behavior changes] -> Make only file moves, import updates, public APIs, and resolver changes; verify existing tests without changing assertions.

## Migration Plan

1. Keep the completed Shared API extraction.
2. Add the App bootstrap module and retain the root build adapter.
3. Move flat pages into page slices with public APIs and update Inertia resolution.
4. Move root components, stores, and types into transitional Shared segments with public APIs.
5. Update runtime, type-only, and test mock imports, then remove legacy aliases and empty root directories.
6. Run focused tests, the complete frontend validation, a production asset build, and strict OpenSpec validation.
7. Roll back by restoring the previous file locations, resolver, aliases, and imports if validation reveals a compatibility issue.

## Open Questions

None.
