## Context

The frontend package under `assets/` uses Bun scripts that are exposed through stable Mix aliases and top-level just recipes. Biome currently provides both linting and formatting from a root-level configuration. Qwinto and Koala Rescue Club instead share an ESLint flat configuration with JavaScript, TypeScript, and Svelte recommended rules, plus Oxfmt for formatting.

The migration must preserve the D20 command boundary and its 100-column, two-space formatting policy. Existing unrelated display-mode changes in the working tree must not be reformatted or included in the migration commit.

## Goals / Non-Goals

**Goals:**

- Align D20 with the ESLint and Oxfmt setup already used by Qwinto and Koala Rescue Club.
- Apply ecosystem-aware linting to JavaScript, TypeScript, and Svelte sources.
- Preserve the existing `mix assets.*` and `just` command interfaces.
- Remove tracked Biome configuration, dependencies, and directives.

**Non-Goals:**

- Reformat the full frontend source tree as part of the tooling migration.
- Change runtime behavior, TypeScript compiler strictness, frontend tests, or public contracts.
- Upgrade unrelated frontend dependencies.

## Decisions

### Use ESLint flat configuration under `assets/`

Add `assets/eslint.config.mjs` using `@eslint/js`, `typescript-eslint`, `eslint-plugin-svelte`, and `globals`, adapted from the two game repositories. The `.mjs` extension matches D20's existing ESM configuration files without changing package-wide module interpretation. Svelte parser options will load the local Svelte configuration and TypeScript project service.

Inertia page components are excluded from `svelte/no-unused-props` because their `InertiaProps` type necessarily includes the framework's open page-props index signature, which the rule reports as unused even when all declared page props are consumed. TypeScript and the remaining ESLint rules still cover those files.

Alternative considered: retain Biome linting and add only Oxfmt. This would not achieve cross-repository rule alignment and would retain duplicate tooling.

### Use Oxfmt only for formatting

Add `assets/.oxfmtrc.json` with 100-column output, two-space indentation, and Svelte support. Preserve the current exclusions for vendored JavaScript and CSS instead of introducing a repository-wide formatting diff.

Alternative considered: let ESLint own formatting. The sibling repositories intentionally separate semantic fixes from formatting, and ESLint's core configuration does not replace a formatter.

### Preserve command names while separating responsibilities

Keep `format`, `format.check`, `lint`, and `check`. `format` will run ESLint fixes before Oxfmt, `format.check` will run Oxfmt in check mode, `lint` will run ESLint, and `check` will compose the format and lint checks. Mix aliases and just recipes therefore require no contract changes.

### Update dependencies through Bun

Remove `@biomejs/biome`, add the same ESLint/Oxfmt dependency set used by the sibling clients, and regenerate `assets/bun.lock` with Bun. Existing runtime dependency versions remain untouched.

## Risks / Trade-offs

- [ESLint reports rules that Biome did not enforce] -> Fix only genuine migration findings or narrowly configure declaration-file behavior, then validate the complete frontend source set.
- [Oxfmt produces different output from Biome] -> Preserve the main formatting parameters and avoid a full source rewrite in this change.
- [Formatter or linter traverses vendored assets] -> Encode explicit ignores for `vendor/`, `css/`, dependencies, and generated output.
- [Dirty worktree changes are accidentally committed] -> Stage explicit migration paths and verify the cached diff before committing.

## Migration Plan

1. Add ESLint and Oxfmt configuration and dependencies while updating the existing scripts.
2. Remove Biome configuration and tracked directives.
3. Run format check, lint, typecheck, frontend tests, and strict OpenSpec validation.
4. Commit and push only migration-related paths.

Rollback restores `biome.json`, the Biome dependency and scripts, the previous lockfile, and the removed directive. No data or runtime rollback is required.

## Open Questions

None.
