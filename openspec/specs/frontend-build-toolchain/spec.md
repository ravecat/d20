# frontend-build-toolchain Specification

## Purpose
TBD - created by archiving change migrate-assets-to-vite-8. Update Purpose after archive.
## Requirements
### Requirement: Vite 8 frontend toolchain
The frontend package SHALL use Vite 8 with a Vite 8 compatible Svelte plugin while preserving the existing Svelte 5, Tailwind, Vitest, and Bun command boundaries.

#### Scenario: Install frontend dependencies
- **WHEN** a developer installs the locked frontend dependencies through the repository asset setup command
- **THEN** dependency resolution completes without an incompatible Vite peer dependency
- **AND** the resolved Vite major version is 8

### Requirement: Rolldown production entries
The Vite production build SHALL use Rolldown-native configuration and SHALL retain `js/app.js` and `css/app.css` as independent build entries.

#### Scenario: Build production assets
- **WHEN** a developer runs `mix assets.build`
- **THEN** Vite emits production assets under `priv/static`
- **AND** `priv/static/.vite/manifest.json` contains entry records for `js/app.js` and `css/app.css`

### Requirement: Phoenix backend integration
The Vite 8 toolchain SHALL preserve the Phoenix Vite development watcher, generated manifest consumption, explicit module-preload polyfill, and `phoenix-colocated` module resolution.

#### Scenario: Render through the development watcher
- **WHEN** Phoenix starts with its configured Vite watcher
- **THEN** the shell loads the Vite client and application entries from the development asset server
- **AND** Svelte and Phoenix template updates continue through their existing HMR or reload boundaries

#### Scenario: Resolve production entries through Phoenix
- **WHEN** Phoenix renders a layout against the generated production manifest
- **THEN** the application JavaScript entry, its associated styles, and the independent CSS entry can be resolved by their existing source names

### Requirement: Svelte TypeScript preprocessing
The frontend TypeScript configuration SHALL preserve type and value imports in the form required by the upgraded Svelte preprocessing pipeline.

#### Scenario: Check TypeScript Svelte components
- **WHEN** a developer runs `mix typecheck`
- **THEN** TypeScript and Svelte checks complete using the repository's existing strict, bundler-oriented project configuration

### Requirement: Tailwind plugin resolution
The frontend stylesheet SHALL load DaisyUI and its theme extension through JavaScript plugin entries compatible with Vite 8 resolution while preserving the existing component and custom theme configuration.

#### Scenario: Compile application styles
- **WHEN** a developer builds the CSS entry through Vite 8 and the Tailwind Vite plugin
- **THEN** DaisyUI plugin loading resolves JavaScript rather than the package's no-build browser CSS entry
- **AND** the configured light and dark themes are included in the generated application styles

### Requirement: Migration isolation
The Vite 8 migration SHALL NOT introduce a custom browser-support query, compatibility linter, additional polyfill policy, or unrelated direct dependency upgrade.

#### Scenario: Inspect the migration dependency diff
- **WHEN** the Vite 8 migration is reviewed before the browser-policy change
- **THEN** its direct dependency changes are limited to Vite and the required Svelte Vite plugin
- **AND** browser-policy integration remains absent until the dependent change is applied
