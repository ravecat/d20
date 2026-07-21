## 1. Establish Migration Baseline

- [x] 1.1 Record the resolved Vite, Svelte plugin, Tailwind plugin, Vitest, Svelte, and Bun versions and confirm the pre-migration frontend checks and production manifest entries.
- [x] 1.2 Verify the tracked worktree is clean outside this change before updating the lockfile.

## 2. Upgrade the Build Toolchain

- [x] 2.1 Upgrade Vite to major 8 and `@sveltejs/vite-plugin-svelte` to major 7 through Bun without changing unrelated direct dependency ranges.
- [x] 2.2 Add `verbatimModuleSyntax` to the existing bundler-oriented TypeScript configuration.
- [x] 2.3 Rename the production entry configuration from `rollupOptions` to `rolldownOptions`, resolve DaisyUI plugins through explicit JavaScript entries, and replace the stale esbuild-specific application comment while preserving the module-preload import.

## 3. Validate Vite 8 Integration

- [x] 3.1 Run frontend formatting, linting, typechecking, and the complete frontend test suite.
- [x] 3.2 Build production assets and assert that the generated Vite manifest retains the `js/app.js` and `css/app.css` entry records.
- [x] 3.3 Run focused Phoenix page tests and smoke-test Phoenix-started Vite development loading plus Svelte and template update behavior.
- [x] 3.4 Run `just check`, build the production Docker image through the pinned Bun path, inspect the scoped diff, and validate this OpenSpec change strictly.
