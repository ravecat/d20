## Context

The committed Mix lockfile currently resolves multiple packages covered by active Hex security advisories. Findings include direct dependencies and transitive packages whose safe versions can require their parent packages to move together. The existing `mix.exs` requirements already admit a dependency graph with no current audit findings, so the task is a lockfile refresh rather than a manifest-policy change.

The repository also generates `phoenix-framework` guidance from locked dependency usage rules. Any dependency update must therefore synchronize and review that generated content while preserving the manually owned `implement-playable-game` skill.

## Goals / Non-Goals

**Goals:**

- Resolve every Mix dependency to the latest version allowed by the current requirements.
- Remove every advisory and retirement reported by `mix hex.audit` for the resolved graph.
- Verify application compatibility and generated usage-rule consistency through repository-native checks.
- Keep the update reviewable and fully reversible through the lockfile and any generated guidance diff.

**Non-Goals:**

- Change direct dependency requirements in `mix.exs`.
- Update Bun dependencies or `assets/bun.lock`.
- Change application behavior, public contracts, persistence, deployment configuration, or runtime architecture.
- Introduce a custom security-aware dependency resolver or advisory ignore list.

## Decisions

### Refresh the complete Mix graph in one resolution

Run `mix deps.update --all` so Hex can update related parent and child packages together under the existing requirements. A hand-curated list of currently vulnerable package names was rejected because some safe transitive versions depend on coordinated parent updates, and the installed `mix hex.audit` task reports findings but has no fix mode.

### Preserve manifest requirements

Keep `mix.exs` unchanged unless the resolver proves that no safe graph exists. The current requirements have already been resolved successfully against a clean graph, so widening constraints would add unnecessary compatibility risk.

### Treat a clean audit and repository checks as separate gates

Run `mix hex.audit` to verify the security outcome. Then synchronize dependency-managed usage rules with `mix usage_rules.sync --yes` and run `just check` to cover formatting, frontend lint and tests, type checking, and backend tests. A clean audit alone cannot establish runtime or tooling compatibility.

### Review all generated changes

Inspect `mix.lock`, dependency version transitions, and any generated `.agents/skills/phoenix-framework/` changes. Preserve unrelated worktree edits and the manually owned `.agents/skills/implement-playable-game/` content.

## Risks / Trade-offs

- [Allowed zero-major and transitive major upgrades can contain breaking behavior] - Review the resolved version transitions and rely on the complete repository checks before accepting the lockfile.
- [Updating every dependency creates more churn than fixing only named advisories] - Accept the broader lockfile refresh because the user requested all Mix dependencies and the complete graph has already been shown to resolve cleanly within current requirements.
- [Dependency-authored usage rules can change generated repository guidance] - Regenerate through the configured task, review the diff, and never hand-edit managed sections.
- [New advisories can appear after validation] - Record that audit cleanliness is evaluated against the Hex advisory registry at validation time and keep `mix hex.audit` available for recurring checks.

## Migration Plan

1. Refresh the Mix graph with `mix deps.update --all`.
2. Inspect version transitions and the focused repository diff.
3. Synchronize dependency-managed usage rules and review any generated changes.
4. Run `mix hex.audit`, `just check`, and strict OpenSpec validation.
5. Roll back by restoring the previous `mix.lock` and generated usage-rule files if validation fails; no database or application-data rollback is required.

## Open Questions

None.
