## 1. Bootstrap the Backend Toolchain

- [x] 1.1 Run `mix igniter.install vibe_kit` without agent-document flags, inspect every generated edit, and preserve the existing AGENTS, Recode, Mix alias, and dependency conventions.
- [x] 1.2 Keep Credo, Dialyxir, ExDNA, ExSlop, and Reach as locked `[:dev, :test]`, `runtime: false` dependencies, remove any unnecessary retained VibeKit dependency, and verify the standalone Vibe package is absent.
- [x] 1.3 Add the generated test-environment CLI preference and Dialyzer `:ex_unit` PLT configuration without changing existing project or application options.

## 2. Calibrate Analyzer Policy

- [x] 2.1 Configure strict Credo with ExSlop's recommended high-signal checks, reconcile overlap with `.recode.exs`, run `mix credo --strict`, and fix in-scope findings or document only narrow suppressions.
- [x] 2.2 Run `mix dialyzer`, fix in-scope success-typing findings, and add a warning filter only if a demonstrated false positive requires a narrowly documented exception.
- [x] 2.3 Run ExDNA against maintained backend sources, review every reported clone group, fix in-scope duplication, and check in explicit scope plus the measured maximum clone budget.
- [x] 2.4 Configure Reach with explicit pure-domain, runtime-adapter, and `D20Web.*` layer patterns, forbid pure-domain dependencies on the web layer, and run `mix reach.check --arch --smells` against the current project.
- [x] 2.5 Add focused configuration coverage proving that a pure-domain-to-web dependency is rejected while the intentional application/runtime-adapter-to-web dependency remains allowed.

## 3. Compose Repository Gates

- [x] 3.1 Add the ordered `mix ci` alias for warnings-as-errors compilation, formatting, tests, Credo/ExSlop, Dialyzer, budgeted ExDNA, and Reach, then verify it resolves to `MIX_ENV=test` and uses the existing database-aware test alias.
- [x] 3.2 Update `just check` to run `mix ci` exactly once followed by the OpenSpec lifecycle check, frontend format, lint, test, and type checks, and the Storybook build, removing the separate duplicate backend format and test commands.
- [x] 3.3 Verify production dependency and application metadata exclude VibeKit, Vibe, Credo, Dialyxir, ExDNA, ExSlop, and Reach and that the production application child set is unchanged.

## 4. Document the Workflow

- [x] 4.1 Document `mix ci`, each focused analyzer command, the first Dialyzer PLT build, PostgreSQL test prerequisite, ExDNA budget review, Reach policy, and the role of `just check`.
- [x] 4.2 Document rollback and the handoff to release verification issue #113 without changing the release workflow in this change.

## 5. Validate and Finalize

- [x] 5.1 Format the touched Elixir and configuration files and run Credo/ExSlop, Dialyzer, ExDNA, and Reach independently so each analyzer's result is attributable.
- [x] 5.2 Run `mix ci`, production dependency isolation checks, and `openspec validate --all --strict --no-interactive`.
- [x] 5.3 Confirm public APIs, Phoenix channel contracts, persistence, runtime supervision, game behavior, iframe contracts, and frontend checks remain unchanged; record any remaining tool limitation or follow-up in issue #179.
- [x] 5.4 Complete review, run the final cross-stack gate with the separately tracked Workspace fix from #254, then sync and archive the OpenSpec change.
