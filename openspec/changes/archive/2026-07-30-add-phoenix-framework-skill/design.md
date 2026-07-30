## Context

D20 keeps repository-specific instructions in `AGENTS.md` and a manually maintained playable-game skill in `.agents/skills/implement-playable-game`. Phoenix 1.8.8 publishes UsageRules sub-rules, but it does not publish a ready-made skill or the root rule file required by UsageRules `skills.deps`. The integration therefore needs an explicit `skills.build` definition and a clear generated-file ownership boundary.

## Goals / Non-Goals

**Goals:**

- Generate one reusable `phoenix-framework` skill from Phoenix-family Mix dependencies.
- Keep generated guidance aligned with `mix.lock` and fail repository checks on drift.
- Preserve all manually authored repository and game implementation guidance.

**Non-Goals:**

- Generate or modify root `AGENTS.md` content.
- Generate a separate Elixir/OTP skill from UsageRules' own package rules.
- Import arbitrary prebuilt dependency skills or frontend package guidance.
- Change application runtime behavior or public contracts.

## Decisions

### Build one universal Phoenix skill

Configure `skills.build` with the name `phoenix-framework`, the user-selected description, and `usage_rules: [:phoenix, ~r/^phoenix_/]`. The atom includes the Phoenix package itself; the regular expression includes rule-bearing companion packages such as current or future `phoenix_*` dependencies. Packages without UsageRules contribute no references.

The skill name remains framework-oriented rather than repository-prefixed so the same contract is portable across Phoenix projects. A separate Elixir/OTP skill is excluded because its source would be the UsageRules tool package itself, not an existing D20 framework dependency.

### Keep UsageRules development-only and skills-only

Add `usage_rules` and its documented direct `igniter` companion with `only: [:dev]` and `runtime: false`. Omit `file` and top-level `usage_rules` configuration so synchronization writes only the configured skill directory and never takes ownership of `AGENTS.md`.

### Commit generated output and validate drift

Commit `.agents/skills/phoenix-framework/**` so the skill is available immediately after checkout. Provide an explicit writing command using `mix usage_rules.sync --yes` and a read-only check using `mix usage_rules.sync --check`; run the check from `just check`.

Generated changes remain reviewable dependency changes. The repository instructions state that managed sections are not hand-edited and that `AGENTS.md` takes precedence when generic framework guidance conflicts with D20 architecture.

Alternatives rejected:

- `skills.deps: [:phoenix]` because Phoenix currently publishes only sub-rule files and UsageRules 1.2.6 requires a root `usage-rules.md` for that mode.
- `skills.package_skills` because no installed dependency currently publishes `usage-rules/skills/*/SKILL.md`.
- Root instruction-file generation because it would mix generated package text with curated repository policy.

## Risks / Trade-offs

- [A new `phoenix_*` dependency can add instructions through the regular-expression selector] -> Commit and review every generated diff and fail checks until synchronization is intentional.
- [Phoenix rules include LiveView and HEEx guidance while D20 primarily renders Inertia and Svelte] -> Keep the supplied framework-focused trigger and do not load the skill for Svelte-only tasks.
- [Development tooling adds transitive dependencies] -> Keep the tools out of runtime and verify the production dependency tree.
- [A universal skill name can overlap a user-installed skill] -> Keep the repository copy deterministic and generated from the locked dependencies; project-local context remains the relevant source for this checkout.

## Migration Plan

1. Add and lock the development dependencies and skills-only configuration.
2. Generate and review `.agents/skills/phoenix-framework/**`.
3. Add explicit synchronization and drift-check commands plus ownership documentation.
4. Run focused synchronization checks, production dependency inspection, strict OpenSpec validation, and repository checks.

Rollback is a normal source revert followed by `mix deps.get`; no runtime or data rollback is required.

## Open Questions

None.
