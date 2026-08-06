## 1. Baseline

- [x] 1.1 Record the current `mix hex.audit` findings and confirm the existing `mix.exs` requirements can resolve an advisory-free graph.

## 2. Dependency Refresh

- [x] 2.1 Run `mix deps.update --all`, review every resolved version transition, and confirm the intentional repository dependency diff does not change `mix.exs` or `assets/bun.lock`.
- [x] 2.2 Run `mix usage_rules.sync --yes`, review any dependency-managed `phoenix-framework` guidance changes, and confirm the manually owned `implement-playable-game` skill is unchanged.

## 3. Validation

- [x] 3.1 Run `mix hex.audit` and confirm no retired or security-advisory packages remain.
- [x] 3.2 Run `just check` and resolve any compatibility failures caused by the refreshed dependency graph.
- [x] 3.3 Run strict validation for the completed OpenSpec change and review the final scoped diff for unrelated changes.
