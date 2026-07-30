## 1. Compact client state

- [x] 1.1 Replace the full `xstate` dependency with an exact-version `@xstate/store` dependency and update the Bun lockfile.
- [x] 1.2 Replace the workspace statechart actor with a typed compact event store while preserving the existing `WorkspaceStore` API and derived state.
- [x] 1.3 Preserve close-command, focus, compact, and subscription teardown behavior in focused workspace tests.
- [x] 1.4 Inline the single-use event store into `createWorkspace` and remove client-specific internal naming.
- [x] 1.5 Infer event payloads from transition handlers and rename the all-compact layout variant to `compact`.
- [x] 1.6 Inline the single-use close error fallback.
- [x] 1.7 Remove client-owned close progress and error state, including entry fields and window component props, and type the initial layout context without assertions.
- [x] 1.8 Inline the initial context through explicit store context and event payload generics, allowing transition arguments and returns to be inferred.
- [x] 1.9 Replace the focused session projection's nested conditional with an exhaustive switch without changing layout behavior.
- [x] 1.10 Remove the redundant `WorkspaceEntry` import after inferring derived entry values.
- [x] 1.11 Rename the derived workspace entry transport field from `channelStatus` to `status`.
- [x] 1.12 Expose authoritative `sessions` and the global `layout` directly from `WorkspaceState`, removing `WorkspaceEntry`, `WorkspaceMode`, the focused-id switch, and per-session transport duplication.
- [x] 1.13 Move expanded and compact arrangement into `workspace.svelte` wrappers and component-scoped CSS while keeping compact siblings reachable.
- [x] 1.14 Keep dialogs non-modal, preserve resize controls and browser fullscreen, and remove child-owned spatial layout styles.
- [x] 1.15 Make `workspace.svelte` render application children and own workspace store construction and subscription teardown, then wrap the persistent layout content with it.
- [x] 1.16 Move the application layout to the App layer and colocate the workspace model, types, and internal UI in a `widgets/workspace` slice with a component-only public API.
- [x] 1.17 Remove the pass-through `GameWindow` component and move its dialog, frame, status markup, and scoped styles into `workspace.svelte`.
- [x] 1.18 Keep the default Inertia layout route-agnostic, rename the presentation variant to `narrow`, and export non-default layout metadata from the Home and Developers page public APIs.
- [x] 1.19 Keep `priv/specs/workspace.yaml` for internal validation while explicitly denying Workspace in `D20Web.Plugs.AsyncApi` and removing it from the Developers catalog.
- [x] 1.20 Remove the parent-window Escape handler and keep compaction on the explicit Theater window control.
- [x] 1.21 Stack the Theater wrapper above every other game window and restore selection through the Compact grid.
- [x] 1.22 Remove the redundant disposed flag, disposal method, explicit detach contract, `onDestroy` hook, and now-unused reset transition, relying on the Svelte subscription chain for teardown.
- [x] 1.23 Remove slug-derived workspace label helpers and render generic connection status messages inline.
- [x] 1.24 Move Expand and Compact controls into the workspace renderer, remove global layout props from `Dialog`, and make `compact()` target-free.
- [x] 1.25 Derive the injected session state from the `phoenix-session` generic and remove redundant focus and close membership checks.
- [x] 1.26 Remove session injection options and test-only session type exports, then substitute `phoenix-session` in focused tests.
- [x] 1.27 Standardize client workspace session identifier fields and parameters on `id`.

## 2. Validation

- [x] 2.1 Run focused workspace store tests and resolve regressions.
- [x] 2.2 Run frontend formatting checks, lint, full tests, and type checks.
- [x] 2.3 Run strict OpenSpec validation for `refactor-client-workspace`.
- [x] 2.4 Update focused store, component, and browser layout tests for parent-owned layout.
- [x] 2.5 Run focused tests, frontend checks, type checks, and strict OpenSpec validation.
- [x] 2.6 Update focused component tests for wrapper ownership and rerun frontend and strict OpenSpec validation.
- [x] 2.7 Move focused tests into paths mirroring the App and Workspace widget boundaries, then rerun frontend and strict OpenSpec validation.
- [x] 2.8 Rerun focused Workspace tests, frontend checks, type checks, and strict OpenSpec validation after inlining `GameWindow`.
- [x] 2.9 Cover page-owned layout metadata and persistent variant changes, then rerun focused frontend checks, type checks, and strict OpenSpec validation.
- [x] 2.10 Cover public 404 behavior, internal contract availability, and public catalog omission, then run focused backend and frontend validation.
- [x] 2.11 Remove the obsolete Escape assertion, preserve explicit Compact control coverage, and run focused frontend validation.
- [x] 2.12 Cover initial and newly selected Theater stacking in the browser layout test.
- [x] 2.13 Cover automatic teardown through the workspace subscription chain and rerun frontend type, formatting, lint, and strict OpenSpec validation.
- [x] 2.14 Cover generic workspace connection status messages and rerun focused frontend, type, formatting, lint, and strict OpenSpec validation.
- [x] 2.15 Cover workspace-owned layout controls and rerun focused model, component, browser, type, lint, formatting, and strict OpenSpec validation.
- [x] 2.16 Cover direct focus and close forwarding and rerun focused model, type, lint, formatting, and strict OpenSpec validation.
- [x] 2.17 Rerun focused model, component, browser, type, lint, formatting, and strict OpenSpec validation after removing production test seams.
- [x] 2.18 Rerun focused model, component, browser, type, lint, formatting, and strict OpenSpec validation after the identifier rename.
