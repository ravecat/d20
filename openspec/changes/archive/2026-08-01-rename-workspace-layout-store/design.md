## Context

`createWorkspace()` contains a Phoenix session store, an inner `@xstate/store` instance for browser-local layout, a Svelte readable adapter, and the final composed state. The inner instance is currently called `store`, which is ambiguous within a function containing several store boundaries.

## Goals / Non-Goals

**Goals:**

- Name the inner layout-only store `layout`.
- Make reads, subscriptions, and trigger calls express that responsibility.
- Preserve all types, emitted values, subscriptions, and behavior.

**Non-Goals:**

- Rename the public `WorkspaceStore` or `WorkspaceState.layout`.
- Change the flat `WorkspaceLayout` context.
- Change runtime behavior or tests.

## Decisions

Rename only the local binding and its direct references. Keep the Svelte readable adapter named `context` because it adapts the inner store context, and keep the composed readable named `state` because it emits `WorkspaceState`.

Alternative considered: rename every intermediate to include `layout`. Rejected because `context` and `state` already describe distinct roles, while only the generic `store` binding is ambiguous.

## Risks / Trade-offs

- [Risk] One reference could retain the old name. -> Type checking and repository search verify that no local `store` reference remains.

## Migration Plan

Rename the binding and validate the focused workspace module. Rollback is the inverse rename; no data or deployment migration is required.

## Open Questions

None.
