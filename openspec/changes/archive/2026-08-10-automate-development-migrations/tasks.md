## 1. Watched Development Startup

- [x] 1.1 Compose `setup` before `phx.server` in the existing `serve` Mix alias so setup failure gates Endpoint startup.
- [x] 1.2 Exclude `priv/repo/migrations/` from the `watchexec` roots so editing a migration cannot trigger its execution.
- [x] 1.3 Make every watched child invoke the existing `mix serve` alias without duplicating setup before `watchexec`.
- [x] 1.4 Preserve `start` as a backward-compatible delegation to `serve`.
- [x] 1.5 Document migration-file exclusion, full setup on other watched events, and the forward-only non-destructive database boundary.

## 2. Validation

- [x] 2.1 Validate Just syntax and dry-run rendering for the default and overridden `serve` arguments.
- [x] 2.2 Validate Mix formatting, `serve` and `start` alias order, and full setup against the currently selected development repo.
- [x] 2.3 Run strict validation for this change and the complete OpenSpec tree, then review the diff for unrelated modifications.
