## Why

Completed OpenSpec changes can remain in the active catalog after their implementation and validation finish, while older active changes can lose their delivery linkage. This makes the active list unreliable for planning and leaves contributors without a repeatable, read-only way to detect lifecycle drift before delivery is declared complete.

## What Changes

- Add a repository-native read-only OpenSpec lifecycle check that runs strict validation, rejects completed-but-unarchived active changes, and rejects active changes without a durable GitHub Issue link.
- Include the lifecycle check in the existing cross-stack `just check` workflow without changing OpenSpec files as a side effect.
- Document the evidence, specification sync, archival, issue reconciliation, exceptional-retention, and final verification sequence for contributors.
- Reconcile the currently active change catalog by archiving verified-complete entries and adding missing delivery links to legitimately incomplete entries without losing their history.

## Capabilities

### New Capabilities

- `openspec-change-lifecycle`: Defines active-change linkage, read-only lifecycle validation, completion evidence, specification synchronization, archival, and exceptional retention.

### Modified Capabilities

None.

## Impact

- Affects repository development tooling, the aggregate `just check` workflow, contributor documentation, and OpenSpec planning artifacts.
- Adds no production dependency, database migration, runtime supervision child, public API change, session compatibility change, iframe contract change, or game behavior change.
- Rollback removes the lifecycle checker and its `just check` entry while leaving reconciled OpenSpec archives and durable specifications intact as delivery history.
- Tracks [GitHub issue #153](https://github.com/ravecat/d20/issues/153).
