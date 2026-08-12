## 1. Storybook Toolchain

- [x] 1.1 Add and lock the Storybook 10 Svelte/Vite, docs, accessibility, CLI, and ESLint development dependencies with frontend run and static-build scripts.
- [x] 1.2 Add typed Storybook main and preview configuration that discovers catalog sources, disables telemetry, and loads the production stylesheet.
- [x] 1.3 Verify Storybook uses the shared Vite configuration without a Storybook-specific environment mode or backend dependency.

## 2. Catalog Sources

- [x] 2.1 Add a typed CSF3 smoke story for the production Player Count Label with meaningful deterministic states and controls.
- [x] 2.2 Document story placement, reusable fixture ownership, module mocking, and the prohibition on live transports or copied production markup.

## 3. Tooling and Commands

- [x] 3.1 Include Storybook configuration and stories in TypeScript and Storybook-aware ESLint checks while excluding generated static output from Git, ESLint, and Oxfmt.
- [x] 3.2 Add a Mix asset alias for static Storybook builds and include it in the root aggregate validation workflow while using the existing `just assets` dispatcher for development arguments.
- [x] 3.3 Document the `just assets storybook` and static-build workflows and their relationship to existing browser tests in the repository README.

## 4. Validation

- [x] 4.1 Run frontend formatting, linting, type checking, tests, the production asset build, and the static Storybook build; fix all task-caused failures.
- [x] 4.2 Start Storybook without Phoenix and verify the smoke story, controls, accessibility panel, and desktop and narrow viewport rendering in a real browser.
- [x] 4.3 Run `just check`, strict OpenSpec validation, and confirm no Storybook generated output is tracked.
- [x] 4.4 Remove the redundant Storybook environment mode and revalidate the development and static-build commands against the shared Vite configuration.
- [x] 4.5 Move static catalog output to `priv/static/storybook`, expose the generated subtree through Phoenix static paths without adding it to production deploy, remove obsolete asset-package ignores, and revalidate the build and served artifact.
- [x] 4.6 Remove the redundant root `storybook` recipe, restore the unmodified project command contract, document `just assets storybook [args...]`, and verify generic dispatcher argument forwarding.
- [x] 4.7 Make the Storybook development script automatically use the nearest available port when 6006 is occupied, document the non-opening behavior, and verify default and explicit port selection with argument forwarding.
- [x] 4.8 Add and lock Concurrently, supervise `restart-or-serve` and Storybook with prefixed logs, and extend `just up` after Docker Compose startup.
- [x] 4.9 Document and verify combined fresh-start output, successful existing-server reuse, failure cleanup, and preserved standalone Storybook behavior.
- [x] 4.10 Move Concurrently from the frontend package into the Nix development shell, declare the unchanged composite command in `just up`, and verify standalone Storybook plus root orchestration command boundaries.
