## Context

The workspace combines two kinds of state:

- `phoenix-session` owns the authoritative channel lifecycle and complete `Workspace` snapshots from the server.
- The browser owns transient presentation state: the focused session and whether all windows are compact.

The current implementation models the browser state with a full XState machine and adapts its actor snapshot into a Svelte store. The workspace uses flat event transitions but does not use hierarchical or parallel statecharts, invoked actors, or actor composition.

## Goals / Non-Goals

**Goals:**

- Keep the authority boundary visible in one workspace factory.
- Express all browser-local mutations as typed events and immutable transitions.
- Compose the server snapshot and local state into the existing read-only `WorkspaceStore`.
- Keep global layout in the workspace boundary instead of copying an effective mode onto each session.
- Keep workspace store construction inside the persistent workspace component and let its subscription own teardown.
- Colocate the workspace model, workspace-specific types, and internal window UI in one FSD widget slice.
- Keep application composition in the App layer and expose only the workspace component to it.
- Keep page-specific layout presentation metadata in the owning page public API instead of branching on Inertia page names in application bootstrap.
- Stack the Theater window above every other game window and restore the selectable window grid through Compact.
- Keep compaction available through an explicit window control without an unreliable parent-window keyboard shortcut.
- Keep the Workspace AsyncAPI contract available for internal verification without publishing it as developer documentation.
- Reduce shipped state-management code and machine-specific boilerplate.
- Let Svelte auto-unsubscription define teardown without manual disposal APIs or a second disposed lifecycle state.
- Preserve focus, compact, close-command, and subscription teardown behavior without duplicating close progress in presentation state.

**Non-Goals:**

- Change the workspace channel payload, server behavior, or `phoenix-session`.
- Change the workspace channel wire contract or delete its internal AsyncAPI document.
- Persist browser-local window layout across reloads.
- Add new window modes or user-visible behavior.
- Add a cross-document keyboard protocol between game iframes and the workspace shell.
- Introduce a general application-wide state framework.

## Decisions

### Use `@xstate/store` for browser-local events

The local state will use `createStore` with a discriminated layout value. Transitions remain event-driven and type-safe while avoiding the full statechart runtime.

Alternatives considered:

- Full `xstate`: retains visualization and statechart features, but the workspace does not use enough of those features to justify its runtime and source overhead.
- A local Svelte `writable` reducer: has no dependency cost, but would duplicate event-store mechanics and remove the direct upgrade path to XState if the state model later requires statecharts.
- `@xstate/svelte`: improves component lifecycle integration but depends on full `xstate`, so it does not address the main cost.

### Keep one workspace factory

`createWorkspace` will create the Phoenix session, event store, reactive composition, and public methods in one scope. The single-use event store will not have a separate client-specific factory because it is an implementation detail of the client workspace rather than an independent boundary.

### Keep transport and local state separate, then derive the public store

The `phoenix-session` value and local store snapshot remain independent inputs to one Svelte `derived` store. Server events cannot overwrite presentation-only state, and local events cannot mutate authoritative membership descriptors.

The public state contains the authoritative session descriptors and the single discriminated layout value. It does not create presentation-specific entry objects, duplicate transport status per session, or store a second focused session identifier.

### Let the workspace component own spatial layout

`workspace.svelte` interprets the global layout while rendering the authoritative session list. It marks the effective expanded wrapper from the layout and session order, and component-scoped CSS arranges that wrapper and the remaining compact wrappers. The expanded wrapper has the highest sibling stacking order so the Theater window is above every other game window.

`workspace.svelte` renders each `Dialog`, iframe `Frame`, and transport status overlay directly. `Dialog` receives only the effective expanded boolean needed to render its resize control. It does not position itself or choose the global workspace layout. The dialog remains non-modal; the explicit Compact control exits Theater and restores the selectable grid, while browser fullscreen remains local to the selected window surface.

Compaction remains an explicit window-control action. The workspace does not register a parent-window Escape listener because keyboard events dispatched inside an iframe belong to that embedded document and do not bubble into the shell document. Supporting a truly global shortcut would require an explicit cross-document protocol with every game module, which is outside this change.

### Let the persistent workspace component own its store

`workspace.svelte` accepts the application `children` snippet, creates the workspace store once during component initialization, and renders the children without adding a layout-affecting DOM wrapper. The application layout wraps its content with the workspace component and does not create or pass a workspace store.

The component's `$workspace` auto-subscription is the lifecycle owner. On unmount, Svelte unsubscribes from the derived workspace store; the derived store releases its `phoenix-session` dependency; and `phoenix-session` leaves the active channel when its last subscriber disappears. No `onDestroy`, `dispose`, `detach`, or disposed flag is needed at the widget boundary. Closing the browser tab destroys the complete JavaScript context and socket.

The default Inertia layout keeps the workspace component mounted while replaceable page content changes, so the same workspace channel and embedded windows survive client navigation. Store creation remains synchronous because the component immediately consumes the store; deferring construction to `onMount` would add a nullable render state without improving the subscription-owned channel lifecycle.

### Treat Workspace as a widget and Layout as App composition

The persistent workspace is a cross-page composite UI block with its own transport lifecycle and presentation model, so it belongs in `widgets/workspace`. Its store implementation and workspace-specific types remain together in `model/workspace.ts`; `workspace.svelte`, the dialog, and iframe frame remain internal to the slice's `ui` segment. A separate game-window component is unnecessary because its markup and status overlay have no lifecycle or reuse independent from the workspace renderer.

The slice public API exports only the persistent workspace component because no production consumer needs direct access to its model. The application layout moves to the App layer and imports that component through `widgets/workspace/index.ts`. Generic socket and module transport primitives remain in Shared, while session descriptors used by page and lobby flows remain in the existing shared session type surface.

### Let page public APIs own layout presentation metadata

The Inertia bootstrap always selects the same default application layout without inspecting the resolved page name. Pages that require the narrow application chrome export `{ variant: "narrow" }` from their slice public API; pages without metadata use the layout default.

Inertia merges the page-owned props into the default layout while keeping the layout component mounted. This preserves the workspace channel and embedded windows across navigation without coupling application bootstrap to the current route catalog. The layout variant describes presentation rather than page purpose, so the old `catalog` name becomes `narrow`.

### Keep side effects at the workspace boundary

The public `close` method forwards directly to `session.close`. Close progress, errors, and timeouts are not copied into workspace presentation state; the next authoritative snapshot determines whether the window remains visible.

### Keep the Workspace AsyncAPI contract internal

The Workspace contract remains under `priv/specs/workspace.yaml` for repository-level validation and maintenance. It is not part of the public game integration surface, so the Developers page does not list it and the AsyncAPI plug explicitly rejects the reserved `workspace` slug for both reference and raw responses.

The explicit rejection precedes game registry lookup so a future registry entry with the same slug cannot accidentally publish the internal contract.

### Adapt subscription lifecycle explicitly

The generic `@xstate/store` subscription will be wrapped in a Svelte `readable`. Svelte subscription teardown will unsubscribe that adapter and the Phoenix session dependency. The session library leaves its active channel when its last subscriber disappears, so the component does not need a parallel manual lifecycle.

## Risks / Trade-offs

- [The compact store does not encode hierarchical statecharts] -> Use a discriminated layout value for the current mutually exclusive modes; migrate to full XState only when actual statechart features are required.
- [Dependency APIs can evolve independently] -> Pin `@xstate/store` to an exact version and cover the public workspace behavior with focused tests and TypeScript checks.
- [Repeated clicks can send duplicate close commands] -> Keep authoritative close handling and idempotency on the server; the client does not invent a second lifecycle for the command.
- [Close errors are no longer shown in the workspace window] -> Keep the workspace presentation model limited to authoritative snapshots and layout state.
- [Removing `showModal()` removes native backdrop and inert behavior] -> Treat Theater as workspace layout rather than a modal task; stack it above sibling windows and retain explicit compact and fullscreen controls.
- [The Theater window covers compact siblings] -> Use the explicit Compact control to restore the grid before selecting another window.
- [Removing the Escape shortcut removes one keyboard path] -> Keep the Compact button keyboard reachable and avoid promising a shortcut that fails whenever the game iframe owns focus.
- [A future game registry entry could reuse the `workspace` slug] -> Reject the reserved slug before registry resolution and cover both public endpoints with 404 tests.

## Migration Plan

1. Replace the `xstate` dependency with exact-version `@xstate/store`.
2. Replace the machine actor with a compact event store and Svelte subscription adapter.
3. Remove close progress and error fields from workspace entries and window component props.
4. Expose sessions and layout directly, then move expanded and compact positioning into the workspace component.
5. Move workspace store construction from the application layout into the persistent workspace wrapper and rely on its auto-subscription for teardown.
6. Move the persistent layout to the App layer and colocate the complete workspace implementation in `widgets/workspace`.
7. Inline the pass-through game-window component into the workspace renderer.
8. Move non-default layout presentation metadata into the owning page public APIs.
9. Remove Workspace from the public developer catalog and explicitly deny its reference and raw AsyncAPI endpoints while retaining the internal document.
10. Remove the parent-window Escape handler and keep compaction on the explicit window control.
11. Raise the Theater wrapper above every compact sibling and cover the stacking transition in the browser test.
12. Remove the redundant disposed flag, disposal method, explicit detach contract, `onDestroy` hook, and reset transition.
13. Run frontend formatting, lint, unit tests, browser layout tests, backend plug tests, and type checks.

Rollback restores the previous dependency and workspace local-state implementation. No persisted state or server migration is involved.

## Open Questions

None.
