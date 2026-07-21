## 1. Establish the Migration Baseline

- [x] 1.1 Confirm the completed Vite 8, ESLint/Oxfmt, and browser-policy changes are the accepted package and lockfile baseline, then record the scoped worktree state.
- [x] 1.2 Record the resolved TypeScript, `typescript-eslint`, `svelte-check`, Svelte, Vite, and Bun versions and run the existing `bun run typecheck`, frontend lint, frontend tests, and production asset build.
- [x] 1.3 After one warm-up, capture at least five serial samples and medians for standalone TypeScript 5.9 checking, complete `bun run typecheck`, and `mix assets.build` on the unchanged source revision.

## 2. Migrate the Compiler Layout

- [x] 2.1 Remove `baseUrl` from `assets/tsconfig.json` while preserving every `paths` alias, strictness option, explicit ambient type, and included file pattern.
- [x] 2.2 Replace the TypeScript 5.9 dependency with TypeScript 7.0 under `@typescript/native` and TypeScript 6.0 under the canonical `typescript` package name, then regenerate `assets/bun.lock` through Bun.
- [x] 2.3 Verify `bun run tsc --version` resolves TypeScript 7.0.x, importing `typescript` resolves the 6.0.x API, compiler API consumers use that supported package, and the dependency diff contains no unrelated direct upgrade.

## 3. Validate Compatibility and Behavior

- [x] 3.1 Run the TypeScript 6 bridge check through its package binary with stable type ordering, native TypeScript 7 checking, `bun run typecheck`, and `mix typecheck`; resolve only demonstrated migration errors without changing runtime behavior.
- [x] 3.2 Run frontend format checking, linting, the complete frontend test suite, `mix assets.build`, and assert that the generated manifest retains the `js/app.js` and `css/app.css` entry records.
- [x] 3.3 Run `just check` and inspect warnings for unsupported TypeScript peers, changed Vite behavior, or application source churn.

## 4. Verify Performance and Scope

- [x] 4.1 Repeat the warm-up and five-sample benchmark on the migrated dependency tree, report raw samples and medians, and confirm standalone TypeScript 7 checking is at least twice as fast as the TypeScript 5.9 baseline.
- [x] 4.2 Report complete typecheck timing separately, treat Vite build timing only as a non-regression observation, and investigate any repeatable production build regression greater than 10 percent.
- [x] 4.3 Review the final manifest, lockfile, configuration, generated assets, and scoped diff for migration isolation, then validate `migrate-assets-to-typescript-7` with OpenSpec strict mode.
