## Context

The shared Vite configuration currently maintains an explicit `optimizeDeps.include` list for Inertia, Phoenix, and Svelte. Vite 8 can discover these imports automatically, but its cold dependency scan fails when the shared form configuration imports the published `@sjsf/basic-theme/extra-widgets/radio.svelte` implementation subpath directly. The package also publishes a JavaScript `radio-include` entry that imports the component and registers it in the theme definitions. Consuming that entry avoids making the application depend on the component implementation subpath while preserving the same radio widget.

The browser-test project has test-specific optimizer exclusions and aliases. The application development environment should not inherit them when the shipped import graph can be discovered without custom optimizer configuration.

## Goals / Non-Goals

**Goals:**

- Complete a forced cold Vite dependency scan without the SJSF package-exports error.
- Let Vite discover ordinary and linked application dependencies automatically.
- Keep SJSF radio selection, rendering, and production bundling unchanged.

**Non-Goals:**

- Upgrade or patch Vite, the Svelte plugin, or SJSF.
- Disable dependency optimization globally.
- Change the browser-test project configuration.

## Decisions

### Use the package's radio registration entry

Import `@sjsf/basic-theme/extra-widgets/radio-include` for its documented registration side effect, then resolve `radioWidget` through the package's existing theme function. This retains SJSF's component ownership and avoids directly naming the exported `.svelte` implementation in the application dependency graph.

Alternative considered: exclude `@sjsf/basic-theme` or all SJSF packages from dependency optimization. That bypasses the immediate failure but encodes a development-only exception when the package already exposes a JavaScript registration entry for this use case.

Alternative considered: pass custom package conditions into Rolldown. The failure originates from the application's direct component implementation import, so duplicating low-level resolver configuration would couple the application to optimizer internals without removing that dependency.

### Remove the explicit include list

Delete the manually maintained application `include` list and rely on Vite's automatic discovery. The shipped entry point statically imports the affected dependencies, and a forced scan verifies that linked Phoenix packages remain resolvable without manual enumeration.

Alternative considered: retain the include list and add the exclusion. That would fix the immediate error but preserve configuration that duplicates Vite's discovery results and must be updated whenever application dependencies change.

## Risks / Trade-offs

- [Risk] Automatic discovery could optimize a linked dependency later than the old explicit list. -> Run a forced cold scan from the shipped entry point and require it to finish without resolution errors.
- [Risk] The registration entry mutates package theme definitions through a side effect. -> Import it explicitly before constructing the custom resolver and cover radio selection and rendering through existing focused tests.
- [Risk] A later SJSF release could change the registration entry. -> Keep the import on the package's exported JavaScript entry and let type checking and the production build detect contract changes.

## Migration Plan

Apply the form import and Vite configuration changes, then restart the development server with forced dependency optimization once. No data, runtime, deployment, or package migration is required. Rollback restores the direct component import and previous `include` list.

## Open Questions

None.
