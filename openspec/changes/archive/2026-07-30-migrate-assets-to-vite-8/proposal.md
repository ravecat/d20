## Why

The shell assets still run on Vite 6, while the supported Vite and Svelte plugin toolchain has moved to Vite 8 and its Rolldown, Oxc, and Lightning CSS pipeline. Migrating now removes the incompatible Vite 6 peer constraint from `@sveltejs/vite-plugin-svelte` and avoids building further browser-support tooling on deprecated Rollup and esbuild configuration.

## What Changes

- Upgrade Vite from 6 to 8 and `@sveltejs/vite-plugin-svelte` from 5 to the Vite 8 compatible major.
- Adopt the TypeScript module setting required by the upgraded Svelte preprocessing pipeline.
- Replace deprecated `build.rollupOptions` configuration with `build.rolldownOptions`.
- Resolve DaisyUI Tailwind plugins through their explicit JavaScript entries so Vite 8 does not select the package's browser CSS bundle for a JavaScript plugin load.
- Preserve the existing Bun, Phoenix watcher, manifest, module-preload, Tailwind, Svelte, Vitest, and colocated-hook behavior.
- Refresh the Bun lockfile without upgrading unrelated direct dependencies.

## Capabilities

### New Capabilities

- `frontend-build-toolchain`: Defines the supported Vite 8 production build and development integration, including Svelte preprocessing, Phoenix manifest output, and HMR behavior.

### Modified Capabilities

None.

## Impact

- Affects `assets/package.json`, `assets/bun.lock`, `assets/vite.config.mjs`, `assets/tsconfig.json`, DaisyUI plugin paths in `assets/css/app.css`, and one stale esbuild comment in `assets/js/app.js`.
- Changes the internal frontend bundler, transformer, JavaScript minifier, and CSS minifier from the Vite 6 pipeline to Vite 8 defaults.
- Does not change routes, runtime payloads, persistence, sessions, iframe module contracts, or public frontend component interfaces.
- Rollback restores the previous dependency ranges, lockfile, TypeScript option, and Rollup-named build configuration.
