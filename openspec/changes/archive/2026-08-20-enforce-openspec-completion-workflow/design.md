## Context

The repository already requires OpenSpec-backed delivery and has archived historical changes under `openspec/changes/archive/`, but enforcement is split between contributor guidance and manual inspection. `openspec validate --all --strict --no-interactive` detects structurally invalid artifacts, while `openspec list --json` identifies active changes and their completion status. Neither command alone enforces archival or durable Issue linkage.

The current active catalog contains legitimately incomplete delivery work, one verified-complete historical change awaiting its last broad check, and older changes whose proposals predate the Issue-linkage gate. The reconciliation must preserve those records rather than deleting or rewriting their implementation history.

## Goals / Non-Goals

**Goals:**

- Provide one read-only repository command that combines strict validation with lifecycle-specific checks.
- Fail with actionable change names when an active change is complete but unarchived or lacks a GitHub Issue link.
- Make the check part of `just check` and cover its classification logic with focused tests.
- Document the evidence, sync, archive, verification, and exceptional-retention sequence.
- Reconcile current active entries without implementing unrelated incomplete product work.

**Non-Goals:**

- Automatically archive, edit, or delete OpenSpec changes.
- Query or mutate GitHub from the lifecycle checker.
- Infer that an incomplete change is stale from its age.
- Finish unrelated implementation, deployment, or manual verification tasks solely to reduce the active-change count.
- Change production runtime behavior or public contracts.

## Decisions

### Use a Mix alias backed by a focused Elixir checker

Expose `mix openspec.check` through the existing Mix alias boundary. The alias compiles development code and invokes a focused Mix task that shells out to the checked-in OpenSpec CLI, decodes its JSON with the existing Jason dependency, and inspects proposal files.

This keeps JSON handling portable inside the established Elixir toolchain. A shell script with `jq` was rejected because `jq` is not part of the reproducible Nix development shell. A new dependency was rejected because existing dependencies are sufficient.

### Keep the check strictly read-only

The checker runs strict validation, reads `openspec list --json`, and reads each active proposal. It never calls `openspec archive`, updates specifications, writes task checkboxes, or changes GitHub state.

Automatic archival was rejected because specification synchronization and completion evidence require review. The checker reports the exact corrective action instead.

### Define stale as complete but still active

An active change is stale when OpenSpec reports it complete while it remains under `openspec/changes/`. Age alone does not indicate staleness because deployment, migration, manual verification, or external coordination can legitimately keep a change open.

### Require local durable Issue linkage

Every active change proposal contains a full GitHub Issue URL. The check validates the presence and shape of the link without requiring network access or assuming the Issue's current state. GitHub Project status and Issue lifecycle remain managed through the repository's GitHub workflow.

### Preserve exceptional incomplete changes

An incomplete change remains active when at least one delivery task is unchecked and the artifact records why it remains open. Reconciliation adds missing Issue links but does not mark unrelated tasks complete. Verified-complete changes are synced and archived with their full history.

## Risks / Trade-offs

- [Risk] A syntactically valid Issue URL can point to an unrelated or closed Issue. - Mitigation: contributor review and the GitHub completion workflow remain authoritative; the local checker deliberately avoids network dependence.
- [Risk] A completed change can be hidden by leaving an artificial unchecked task. - Mitigation: task descriptions and blocker notes remain reviewable, and completion evidence must match the owning Issue before closure.
- [Risk] Running strict validation inside `just check` increases check duration. - Mitigation: OpenSpec validation is read-only, parallelized by the CLI, and materially protects delivery-state accuracy.
- [Risk] Archiving a historical change can surface specification conflicts. - Mitigation: compare and sync each delta deliberately, preserve the archive, and keep unrelated incomplete changes active.

## Migration Plan

1. Add the checker, focused tests, Mix alias, and `just check` integration.
2. Add missing Issue links to active proposals.
3. Run the checker and broad repository validation.
4. Mark only verified-complete historical validation tasks complete, sync their delta specifications, and archive those changes.
5. Sync and archive this change after every task and `#153` acceptance criterion is complete.
6. Roll back the tooling by removing the alias, task, tests, documentation, and `just check` entry; do not remove reconciled archives or durable specifications.

## Open Questions

None.
