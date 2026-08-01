## Context

`createWorkspace()` already composes the authoritative Phoenix workspace session with browser-local layout intent. The workspace component currently reopens that internal representation and reconciles it with the composed session list to determine which session is expanded. This makes the component responsible for a model invariant and exposes `layout` even though presentation only needs the effective expanded session ID.

The current behavior distinguishes Auto, focused, and Compact intent. Auto follows the first authoritative session, focused retains the requested ID while falling back to the first session when it is absent, and Compact expands no session. That intent must remain available inside the model because the same effective ID can represent different future behavior.

## Goals / Non-Goals

**Goals:**

- Publish one normalized `expandedId: string | undefined` value from `WorkspaceState`.
- Keep `WorkspaceLayout` and its transition intent internal to the workspace model.
- Preserve Auto, focus retention, missing-focus fallback, Compact, session replacement, and subscription behavior.
- Make the workspace component compare session IDs directly with the store-owned value.

**Non-Goals:**

- Replace layout intent with a writable expanded ID.
- Change focus, Compact, close, fullscreen, iframe, transport, or backend behavior.
- Persist or synchronize browser-local presentation state.
- Introduce a new store, dependency, or public protocol field.

## Decisions

### Derive the effective ID in the composed store

The existing Svelte `derived` store will resolve `expandedId` from the current session value and private XState layout context before publishing `WorkspaceState`. This keeps authoritative sessions and local intent separate while placing their reconciliation at the boundary that already composes them.

Alternative considered: store only a writable expanded ID. Rejected because Auto and focused layouts can produce the same current ID but must react differently to later snapshots, and a missing focused session must be able to regain focus if it reappears.

### Publish a stable property and hide raw layout

`WorkspaceState` will contain `expandedId: string | undefined` on every emission and will no longer expose `layout`. The stable property shape makes Compact and an empty session list explicit without requiring consumers to inspect model transitions.

Alternative considered: publish both `layout` and `expandedId`. Rejected because no consumer needs raw layout, it preserves two presentation contracts, and it invites future components to repeat reconciliation.

### Verify derivation at the model boundary

Focused model tests will assert Auto selection, explicit focus, missing-focus fallback and retention, and Compact output through `WorkspaceStore`. Existing component and browser tests remain the behavioral safety net for window presentation and iframe continuity.

## Risks / Trade-offs

- [Risk] Removing `layout` from `WorkspaceState` can expose an unknown internal consumer. -> Repository search confirms the workspace component and focused model tests are the only consumers; type checking will verify the boundary.
- [Risk] Normalizing a missing focused ID could accidentally overwrite the retained intent. -> Keep the XState context unchanged and derive only the emitted `expandedId`; test that a previously missing focused session is selected if it reappears.
- [Trade-off] `undefined` represents both Compact and no available session. -> Presentation needs the same result in both cases, while the private layout retains the distinction required for later snapshots.

## Migration Plan

1. Add store-level derivation and update the `WorkspaceState` contract.
2. Switch the workspace component to `$workspace.expandedId`.
3. Update focused model tests and run targeted frontend validation.

Rollback restores the public layout field and component-local derivation. No data or deployment migration is required.

## Open Questions

None.
