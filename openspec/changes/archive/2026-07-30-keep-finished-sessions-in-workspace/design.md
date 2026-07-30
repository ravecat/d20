## Context

`D20.Sessions.list_runtime/1` returns live Session runtimes whose durable membership contains the authenticated actor. `D20Web.Workspace.snapshot/1` then applies presentation eligibility and currently emits descriptors only for `in_progress` Sessions with configured game modules.

When a game finishes, `D20.Game.Server` first publishes the terminal Session to `D20Web.SessionChannel` and then invalidates affected workspaces because the outer phase changed. The current workspace rebuild excludes the now-`finished` Session, so the frontend removes its existing iframe even though the runtime still owns the final caller-specific projection. A new workspace join has the same exclusion and cannot restore the results.

Sessions are volatile runtime processes with the existing idle-expiry policy. This change provides access to results while that runtime remains live; it does not introduce durable match history.

## Goals / Non-Goals

**Goals:**

- Keep a configured finished Session in every durable member's workspace while its runtime is live.
- Preserve the mounted module across the terminal phase transition so it can display the final projection.
- Restore the same finished result window after a reload or other new workspace join.
- Preserve explicit close, runtime expiry, membership privacy, complete-snapshot semantics, and existing public payload shapes.

**Non-Goals:**

- Persist results after the Session runtime terminates or expires.
- Add a result archive, history page, Session database schema, or migration.
- Add a phase field to Workspace descriptors or make the shell interpret game-specific scores.
- Change game commands, projections, iframe integration, Presence membership, or idle-timeout policy.

## Decisions

### Apply terminal eligibility in the Workspace boundary

`D20Web.Workspace.snapshot/1` will accept outer Session phases `in_progress` and `finished` before resolving the configured game module and building the existing descriptor.

This keeps `D20.Sessions.list_runtime/1` responsible only for live runtime lookup and durable actor membership, while the web boundary continues to own presentation eligibility. Moving the phase filter into `D20.Sessions` was rejected because it would mix shell presentation policy into the domain runtime boundary and could narrow other callers of `list_runtime/1`.

### Preserve the existing descriptor and reconciliation contract

The Workspace descriptor will not gain a phase or result field. On an attached transition, SessionChannel already publishes the terminal caller-specific projection before Workspace invalidation, and reconciliation retains an entry with the same Session id. On a new workspace join, the descriptor supplies the existing module connection, whose SessionChannel join returns the current terminal projection.

Adding terminal state to the Workspace payload was rejected because it would duplicate the authoritative Session projection, require unnecessary frontend and AsyncAPI schema changes, and invite the shell to interpret game-specific results.

### Keep phase invalidation and explicit close behavior

Workspace invalidation will continue comparing outer phases and durable member ids. The `in_progress` to `finished` transition therefore still publishes a complete replacement snapshot, but that snapshot retains the Session descriptor. This preserves the current invalidation model and the required `waiting` to `in_progress` discovery transition.

The existing Workspace `close` operation remains the dismissal mechanism. It removes the actor from durable Session membership, publishes a replacement snapshot without the descriptor, and leaves the shared runtime alive for other members.

### Document eligibility without changing the wire schema

The Workspace AsyncAPI description will state that live `in_progress` and `finished` Sessions are reported and that either can be explicitly closed. Event names, payload shapes, descriptor fields, token claims, and error reasons remain unchanged.

## Risks / Trade-offs

- [Players may expect permanent result history] -> State explicitly that discovery is limited to live runtimes and preserve the existing idle-expiry behavior; durable history remains a separate capability.
- [Finished sessions remain visible until dismissed or expired] -> Preserve the existing explicit close operation so each actor can remove the result window without stopping the shared runtime.
- [A broader phase match could expose waiting lobbies] -> Match only the explicit `in_progress` and `finished` phases and retain configured-module and durable-membership checks.
- [A terminal workspace refresh could remount the iframe and lose client state] -> Preserve descriptor identity and the existing id-keyed workspace reconciliation; cover the retained descriptor and new-join restoration at the channel boundary.

## Migration Plan

1. Deploy the Workspace eligibility and AsyncAPI description together.
2. Existing live Sessions require no state conversion; any live finished runtime observed after the update becomes discoverable on the next workspace snapshot or join.
3. Verify standard and custom-server terminal transitions, new workspace joins, and explicit finished-session close.
4. Roll back by restoring `in_progress`-only eligibility and the prior contract text. No data rollback is required.

## Open Questions

None.
