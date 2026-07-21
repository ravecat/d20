## Context

The `assets/` package currently resolves Vite 6.4.2 with `@sveltejs/vite-plugin-svelte` 5.1.1. The Vite configuration uses a non-HTML JavaScript and CSS entry pair, emits `priv/static/.vite/manifest.json` for `PhoenixVite.Components`, imports the module-preload polyfill explicitly, resolves Phoenix colocated hooks from `MIX_BUILD_PATH`, and runs through the Bun version pinned in `config/config.exs` during development and production image builds.

Vite 8 replaces Rollup and esbuild internals with Rolldown, Oxc, and Lightning CSS. The current configuration is small and uses no custom transforms, CommonJS options, manual chunks, or esbuild hooks, but the Svelte plugin must move to major 7 and its TypeScript preprocessing path inherits the `verbatimModuleSyntax` requirement introduced in major 6.

The first Vite 8 production build also exposed a package-resolution collision in the existing Tailwind CSS input. DaisyUI publishes `index.js` for Tailwind plugin use and declares `daisyui.css` as its browser entry for no-build use. Vite 8's environment resolver selected the browser CSS entry while Tailwind's `@plugin` loader required JavaScript, producing `ERR_UNKNOWN_FILE_EXTENSION` for `daisyui.css`.

## Goals / Non-Goals

**Goals:**

- Run development, tests, typechecking, and production asset builds on Vite 8.
- Keep Svelte, Tailwind, Vitest, Phoenix Vite, colocated hooks, the two manifest entry keys, and explicit module-preload behavior working.
- Preserve configured DaisyUI components and themes through Tailwind plugin compilation.
- Remove deprecated Rollup-named Vite build configuration instead of relying on Vite 8 compatibility conversion.
- Isolate the bundler migration from the later browser-support-policy change.

**Non-Goals:**

- Introduce Browserslist, compatibility linting, custom browser targets, or polyfills.
- Upgrade unrelated direct frontend dependencies.
- Change page behavior, component interfaces, public routes, session contracts, or iframe module integration.
- Adopt the intermediate `rolldown-vite` package unless direct migration exposes a reproducible compatibility defect.

## Decisions

### Upgrade Vite and its required Svelte integration together

Update `vite` to the current Vite 8 range and `@sveltejs/vite-plugin-svelte` to major 7 in the same Bun lockfile operation. Plugin major 7 explicitly requires Vite 8 and the current Svelte 5.55.5 satisfies its Svelte peer range. Vitest 4.1.7 and the resolved Tailwind Vite plugin already declare Vite 8 compatibility, so their direct dependency ranges remain unchanged.

Alternative considered: upgrade every frontend dependency to latest. That would broaden the migration and make failures harder to attribute.

### Make the Svelte TypeScript preprocessing requirement explicit

Add `verbatimModuleSyntax: true` to the existing bundler-oriented TypeScript configuration. This preserves imports according to their written type/value form and meets the Svelte plugin requirement without changing the existing `module`, `moduleResolution`, aliases, strictness, or emitted-output behavior.

Alternative considered: disable `vitePreprocess` TypeScript handling. The application has multiple TypeScript Svelte scripts, so removing the established preprocessor would be a behavior change.

### Use Rolldown-native build configuration

Rename `build.rollupOptions` to `build.rolldownOptions` while retaining the exact `js/app.js` and `css/app.css` inputs. Vite 8 still converts `rollupOptions`, but using the native option avoids a deprecation and makes the active bundler boundary explicit.

The `vite/modulepreload-polyfill` import remains because the application uses non-HTML build inputs. The Phoenix Vite plugin remains enabled outside Vitest because its `handleHotUpdate` and `configureServer` hooks use supported Vite plugin interfaces and do not call Rollup or esbuild internals.

### Resolve DaisyUI as JavaScript for Tailwind plugin loading

Change the existing `@plugin "daisyui"` and `@plugin "daisyui/theme"` references to `daisyui/index.js` and `daisyui/theme/index.js`. This preserves plugin configuration and generated styles while bypassing the package-level browser field only at the Tailwind JavaScript plugin boundary.

Alternative considered: remove `browser` from Vite's global `resolve.mainFields`. That would change application dependency resolution broadly to solve one build-time plugin ambiguity.

Alternative considered: import the precompiled `daisyui.css` browser bundle. That would bypass the configured plugin include behavior and custom theme generation, increasing output and changing the current Tailwind contract.

### Validate observable integration boundaries, not internal bundle bytes

The migration will assert successful package checks and production build, the presence of `js/app.js` and `css/app.css` manifest entries, Phoenix page rendering, and development HMR for both Svelte and Phoenix template changes. Hashed filenames and bundle byte-for-byte equality are not contracts.

## Risks / Trade-offs

- [Rolldown changes CommonJS default import interop] -> Run the complete frontend tests and browser smoke path covering Inertia, Phoenix, Svelte, topbar, and SDK imports; fix an affected dependency rather than enabling Vite's legacy interop globally unless no upstream-compatible path exists.
- [Oxc or Lightning CSS minification changes production output] -> Validate the production build and rendered shell in addition to unit tests, and inspect build warnings before accepting output.
- [Vite 8 resolves DaisyUI's browser CSS entry for a Tailwind JavaScript plugin] -> Use the package's explicit JavaScript entry paths and retain the existing plugin option blocks and generated theme output.
- [Phoenix Vite HMR behaves differently under Vite 8] -> Exercise `.svelte` and `.heex` edits through the Phoenix-started watcher and confirm the watcher terminates with Phoenix.
- [Bun runtime differs from Vite's documented Node engine] -> Run repository Mix aliases, including the production Docker build path when broad validation is reached, using the pinned Bun runtime rather than relying only on a system Node invocation.
- [Vite 8 manifest structure changes] -> Assert the two source entry keys and their emitted files after `mix assets.build` before running Phoenix production-oriented checks.

## Migration Plan

1. Capture the current Vite 6 package checks, production build, manifest keys, and clean repository state.
2. Upgrade only Vite and the Svelte Vite plugin through Bun, then add the TypeScript and Rolldown-native configuration changes.
3. Run formatting, lint, typechecking, frontend tests, production build, manifest assertions, focused Phoenix page tests, and strict OpenSpec validation.
4. Smoke-test Phoenix-owned development startup and HMR. Run `just check` and a production Docker build because the pinned Bun path is part of release assembly.
5. If direct migration fails specifically in Rolldown or a plugin hook, use Vite 7 plus `rolldown-vite` only as a diagnostic intermediate. The committed target remains Vite 8.

Rollback restores the Vite 6 and Svelte plugin 5 dependency ranges, previous Bun lockfile, omitted `verbatimModuleSyntax`, `rollupOptions` name, and old tooling comment. No data or runtime rollback is required.

## Open Questions

None.
