## 1. Replace Frontend Tooling

- [x] 1.1 Add Svelte-aware ESLint flat configuration and Oxfmt formatting configuration under `assets/` with the required exclusions.
- [x] 1.2 Replace Biome package scripts and development dependencies with ESLint and Oxfmt, then regenerate `assets/bun.lock` through Bun.
- [x] 1.3 Remove tracked Biome configuration and inline directives, and update repository tooling guidance.

## 2. Validate the Migration

- [x] 2.1 Run frontend format checking and linting through the existing Mix aliases.
- [x] 2.2 Run frontend typechecking and tests to confirm the tooling migration does not change application behavior.
- [x] 2.3 Verify tracked Biome references are removed and run strict OpenSpec validation for the change.
