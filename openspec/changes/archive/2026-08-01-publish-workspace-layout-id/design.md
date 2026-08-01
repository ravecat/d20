## Context

The workspace has two inputs: authoritative sessions from `phoenix-session` and browser-local layout context from `@xstate/store`. The current composed `WorkspaceState` flattens their expansion result into `expandedId`, while the inner layout context still carries a mode and only focused mode carries an ID. A separate helper then reconciles membership and can replace explicit focused intent with the first available session.

The desired read contract is the layout itself. Every mode exposes an `id`, focused keeps the exact user-selected value, Compact uses `undefined`, and Auto receives the first authoritative session ID when the two stores are composed.

## Goals / Non-Goals

**Goals:**

- Put `id` beside `mode` in the local `createStore` layout context.
- Publish `WorkspaceState.layout` and consume `$workspace.layout.id` directly.
- Keep focused intent exact even when its session is absent.
- Remove `expandedId`, membership fallback, and the one-use helper.

**Non-Goals:**

- Persist browser-local layout or synchronize it across tabs.
- Add session membership to the local presentation store.
- Change focus, Compact, close, fullscreen, transport, or iframe operations.
- Add a backend or public protocol field.

## Decisions

### Model every layout mode with an ID

`WorkspaceLayout` remains a discriminated union, but every variant includes `id`: Auto uses `string | undefined`, focused uses `string`, and Compact uses `undefined`. `WorkspaceLayout` itself is the flat `createStore` context, without a nested `layout` field. The inner store initializes Auto and Compact with `undefined` and writes the event ID for focused mode.

Alternative considered: keep a separate `expandedId`. Rejected because consumers need both the mode and selected ID as one coherent presentation value, and a parallel field duplicates the layout contract.

### Compose the Auto ID inline

The existing Svelte derived store will publish the local context layout unchanged for focused and Compact. For Auto it will publish an Auto layout whose ID is the first current session ID. This is the only mode that depends on authoritative sessions, so the mapping stays inline at the composition boundary and needs no helper.

Alternative considered: push every Phoenix snapshot through the local XState store. Rejected because it would duplicate authoritative session state and introduce synchronization solely to fill a derived Auto value.

### Treat focused ID as exact intent

Focused mode will never scan sessions or substitute a fallback. If the selected session is absent, no current session matches `$workspace.layout.id`; if it reappears, it becomes expanded again without another local transition.

Alternative considered: replace a missing focused ID with the first session. Rejected because the emitted selection would contradict the stored explicit intent and hide a state transition from consumers.

## Risks / Trade-offs

- [Trade-off] A missing focused session leaves all remaining sessions Compact. -> This follows exact intent; returning to Auto or selecting another session requires an explicit transition.
- [Risk] Auto could retain a stale ID if cached in local context. -> Derive the published Auto ID from the current authoritative sessions on every composed store emission without mutating the flat local context.
- [Risk] Consumers could keep reading the removed `expandedId`. -> Repository search and TypeScript/Svelte checking verify all workspace consumers.

## Migration Plan

1. Change the layout union and local transitions to carry `id` in every mode.
2. Publish composed `layout` and update the workspace component.
3. Update model tests and run focused frontend validation.

Rollback restores `expandedId` and its resolver. No data or deployment migration is required.

## Open Questions

None.
