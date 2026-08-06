## Context

AuthDialog receives local mailbox availability through the required global Inertia `auth.local` value. Its existing notice is additionally gated by Login mode, which hides the development destination during registration even though both flows deliver email through the same local adapter.

## Goals / Non-Goals

**Goals:**

- Keep the local mailbox link visible throughout every account-dialog mode and state when `auth.local` is true.
- Preserve the server as the source of truth for whether the development route is available.
- Verify the visible behavior through the existing Header browser harness.

**Non-Goals:**

- Change registration, login, delivery, or confirmation behavior.
- Show development guidance when the local mail adapter or development routes are disabled.
- Change notice copy, styling, routes, shared props, or store state.

## Decisions

### Gate only on server-provided availability

AuthDialog will render the existing notice whenever `page.props.auth.local` is true. Removing the mode predicate is sufficient because the server already combines the two required availability conditions. Adding mailbox visibility to the auth store was rejected because it would duplicate Inertia state and introduce synchronization work.

### Extend the focused browser test across both modes

The existing semantic link assertion will first verify Register mode, then switch to Login and verify the same link remains available. Separate component plumbing or a new end-to-end suite was rejected because the current browser harness already exercises the shared dialog through its public Header interaction.

### Infer the component mode from the store transition

AuthDialog will derive its local mode parameter type from `auth.trigger.switchMode`. The store will keep the mode union inside its context contract without exporting a parallel shared type. Exporting `AuthMode` was rejected because it adds a second public dependency even though the trigger already exposes the authoritative transition payload.

## Risks / Trade-offs

- [Development-only guidance could leak outside development] -> Continue gating on `auth.local`, which is false unless development routes and the Local adapter are both enabled.
- [The notice adds vertical space to registration] -> Accept the consistent guidance because it directly exposes the required local confirmation destination and reuses the existing notice presentation.
- [Mixed uncommitted auth work could be overwritten] -> Patch only the condition and focused assertion, then review the complete diff before commit.

## Migration Plan

1. Update the requirement and focused browser coverage.
2. Remove the Login-mode predicate from the existing notice.
3. Run focused browser tests, frontend checks, and strict OpenSpec validation.
4. Sync the delta into the main specification and archive the completed change.

Rollback restores the Login-mode predicate. No data, session, deployment, or migration rollback is required.

## Open Questions

None.
