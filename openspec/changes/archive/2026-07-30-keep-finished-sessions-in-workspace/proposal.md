## Why

The workspace removes a game window as soon as its Session becomes `finished`, even while the runtime is live and the actor remains a durable member. This prevents players from seeing final scores and outcomes and from restoring those results after a reload.

Tracked by [GitHub issue #72](https://github.com/ravecat/d20/issues/72).

## What Changes

- Keep live configured Sessions discoverable in the actor workspace when their phase is `in_progress` or `finished`.
- Preserve the existing complete-snapshot invalidation on the transition to `finished` without removing the Session descriptor or remounting an attached game window.
- Restore a live finished Session on a new workspace join so its module can receive the terminal caller-specific projection.
- Continue excluding waiting, unconfigured, non-member, explicitly closed, expired, and terminated Sessions.
- Update the Workspace AsyncAPI description and regression coverage for terminal-result access and explicit close.

## Capabilities

### New Capabilities

- `finished-session-workspace-access`: Defines discovery, restoration, result visibility, and explicit dismissal for live finished Sessions in the actor workspace.

### Modified Capabilities

None.

## Impact

- Backend: `D20Web.Workspace` snapshot eligibility and focused WorkspaceChannel tests.
- Public contract: descriptive eligibility semantics in `priv/specs/workspace.yaml`; descriptor and event schemas remain unchanged.
- Frontend and module integration: no code or contract changes; the existing workspace reconciliation and SessionChannel projection flow continue to own iframe continuity and terminal rendering.
- Persistence and runtime compatibility: no migration or stored-state change. Existing live finished runtimes become discoverable immediately after deployment.
- Rollback: reverting the eligibility clause and contract text restores the previous behavior, with finished windows disappearing again.
