## 1. Read-only Lifecycle Checker

- [x] 1.1 Add the focused Elixir lifecycle checker and `mix openspec.check` alias that run strict non-interactive OpenSpec validation and inspect the active change list without writing files.
- [x] 1.2 Reject completed-but-unarchived changes and active proposals without a full GitHub Issue URL, with actionable change names in each failure.
- [x] 1.3 Add focused tests for valid incomplete changes, invalid artifacts, completed active changes, missing Issue links, command failures, and malformed OpenSpec JSON.
- [x] 1.4 Add `mix openspec.check` to the existing `just check` composition without adding a single-action root recipe.

## 2. Contributor Workflow

- [x] 2.1 Document active-change Issue linkage, completion evidence, delta-spec synchronization, dated archival, final absence verification, and the read-only checker command.
- [x] 2.2 Document exceptional retention for incomplete deployment, migration, rollback, external coordination, or manual verification tasks without treating age as completion evidence.

## 3. Active Catalog Reconciliation

- [x] 3.1 Add missing owning Issue links to legitimately incomplete active proposals and retain their unchecked delivery tasks and blocker evidence.
- [x] 3.2 Run the broad repository check required by `introduce-game-registry`, resolve only current failures attributable to that historical change, and complete its final validation task when verified.
- [x] 3.3 Compare and synchronize the verified `introduce-game-registry` delta specifications with authoritative specs, archive the complete change, and preserve its proposal, design, specifications, and task history.
- [x] 3.4 Run the lifecycle checker and confirm every remaining active change is incomplete, valid, and linked to an owning GitHub Issue.

## 4. Validation and Finalization

- [x] 4.1 Format the touched Elixir, documentation, and OpenSpec files and run the focused lifecycle checker tests.
- [x] 4.2 Run `mix openspec.check`, `just check`, and `openspec validate --all --strict --no-interactive`.
- [x] 4.3 Update GitHub issue #153 with the reconciled acceptance criteria and verification evidence.
- [x] 4.4 Sync the `openspec-change-lifecycle` delta into the authoritative specification, archive this change, and confirm it no longer appears in `openspec list --json`.
