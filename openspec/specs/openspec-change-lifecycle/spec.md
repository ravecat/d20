# openspec-change-lifecycle Specification

## Purpose
Define the repository controls that keep OpenSpec changes linked, validated, synchronized, archived, and traceable through delivery.

## Requirements

### Requirement: Active changes retain delivery linkage
Every active OpenSpec change SHALL identify its owning GitHub Issue with a full Issue URL in its proposal before implementation begins.

#### Scenario: Linked active change
- **WHEN** the lifecycle checker inspects an active change whose proposal contains a full GitHub Issue URL
- **THEN** the change satisfies the local delivery-linkage check

#### Scenario: Unlinked active change
- **WHEN** the lifecycle checker inspects an active change whose proposal has no full GitHub Issue URL
- **THEN** the check fails and identifies the unlinked change by name

### Requirement: Lifecycle validation is read-only and actionable
The repository SHALL provide a read-only OpenSpec lifecycle check that runs strict non-interactive validation, detects completed active changes, and returns actionable failure output without modifying planning artifacts.

#### Scenario: Valid incomplete catalog
- **WHEN** every OpenSpec artifact is valid, every active change has delivery linkage, and no active change is complete
- **THEN** the lifecycle check succeeds without changing any file

#### Scenario: Invalid artifact
- **WHEN** strict OpenSpec validation reports an invalid change or specification
- **THEN** the lifecycle check fails and preserves actionable validation output

#### Scenario: Completed active change
- **WHEN** OpenSpec reports a change complete while it remains in the active changes directory
- **THEN** the lifecycle check fails, names the change, and directs the contributor to reconcile and archive it

### Requirement: Cross-stack validation includes lifecycle validation
The aggregate repository check SHALL execute the OpenSpec lifecycle check together with the existing backend and frontend verification stages.

#### Scenario: Repository check encounters lifecycle drift
- **WHEN** `just check` reaches the OpenSpec stage and the lifecycle checker detects an invalid, unlinked, or completed active change
- **THEN** `just check` fails before delivery can be reported complete

### Requirement: Completion preserves specifications and history
Contributors SHALL complete required implementation and validation, synchronize applicable delta specifications, archive the change with its proposal, design, specifications, and task history, and verify the archived change no longer appears as active.

#### Scenario: Change with applicable delta specifications completes
- **WHEN** every required task and validation step is complete and a delta specification changes durable requirements
- **THEN** the contributor synchronizes the delta into the authoritative specification set before archiving the full change record

#### Scenario: Completed change is archived
- **WHEN** a verified-complete change is archived
- **THEN** its full record is preserved under the dated archive and it no longer appears in `openspec list --json`

### Requirement: Exceptional retention remains explicit
An OpenSpec change with outstanding deployment, migration, rollback, external coordination, or manual verification work SHALL remain active with the corresponding task unchecked and the owning Issue link retained.

#### Scenario: Required external verification remains
- **WHEN** implementation is complete but required external verification has not occurred
- **THEN** the change remains active and its task record identifies the outstanding completion evidence
