## Context

`Dialog` currently renders Close and fullscreen controls, while `Workspace` renders Compact or Expand as a separately positioned sibling. The user-visible group is therefore split across two component implementations even though all actions operate on the same workspace window.

`Workspace` also calls `isExpanded` once per rendered session with the same layout and session collection. The helper correctly handles Auto, Focused, Compact, and missing-focused-session fallback behavior, but the result is fundamentally one optional expanded session identifier.

The dialog already renders all ordinary nested markup through its required children snippet. Typing that snippet with `fullscreen` and `toggleFullscreen` lets `Workspace` render the complete block without a second named snippet or a two-way binding. The browser Fullscreen API element reference and synchronization remain inside `Dialog`.

## Goals / Non-Goals

**Goals:**

- Make `Workspace` own one block containing Close, Compact or Expand, and fullscreen controls for each window.
- Replace per-entry expanded-state evaluation with one reactive optional `expandedId`.
- Keep `Dialog` responsible for the native surface and browser-fullscreen mechanics.
- Use the existing children composition boundary instead of adding a dedicated control snippet.
- Preserve every observable control behavior and mounted iframe identity.

**Non-Goals:**

- Move the Fullscreen API implementation or DOM element reference into `Workspace`.
- Introduce a two-way fullscreen binding.
- Change the available controls, labels, visual design, or underlying workspace state model.
- Change the non-modal `dialog.show()` lifecycle or adopt `showModal()`.
- Change Fullscreen API error handling, session-close acknowledgement, channel protocols, or iframe integration.
- Generalize `Dialog` into a public design-system primitive.

## Decisions

1. `Workspace` will derive one optional `expandedId`.

   A `$derived.by` expression will return no identifier for Compact, the focused identifier when it still exists, and the first session identifier for Auto or focused-session fallback. Each keyed entry then derives its boolean with `session.id === expandedId`.

   Alternative considered: retain `isExpanded`. It preserves behavior but repeats collection membership checks for each entry and hides that only one session can be expanded.

2. `Dialog` will provide fullscreen capability through its existing children snippet.

   The required `children` prop becomes a `Snippet` with one context argument containing the current `fullscreen` boolean and `toggleFullscreen` function. `Dialog` continues to derive the boolean from `document.fullscreenElement` and to execute `requestFullscreen()` or `exitFullscreen()`.

   Alternative considered: add a dedicated `controls` or `closeControl` snippet. The existing children boundary can already carry the complete content and avoids another composition API.

3. `Workspace` will render one control block inside the explicit children snippet.

   The block renders Close first, the applicable Compact or Expand action second outside browser fullscreen, and Enter or Exit fullscreen last. It captures the session identifier and expanded boolean lexically, so close and layout behavior stay at their owning workspace boundary while the supplied toggle invokes dialog-owned mechanics.

   Alternative considered: leave the layout button outside the dialog. That would preserve the split implementation the change is intended to remove.

4. Window-control styles will move with their markup to `Workspace`.

   The parent-declared children markup receives the workspace Svelte scope even though `Dialog` renders it inside `.dialog__surface`. One BEM block will therefore own the absolute vertical group, button geometry, pointer states, focus treatment, and SVG presentation without global selectors.

   Alternative considered: keep styles in `Dialog` with global descendant selectors. That would leave presentation ownership split and couple the child to parent-provided class names.

5. Focused tests will verify the unified group and preserved behavior.

   The component suite will expect Close, layout, and fullscreen in the same named group outside fullscreen, Close and Exit fullscreen inside fullscreen, and will continue to exercise Auto, Focused, Compact, fallback, close forwarding, fullscreen transitions, and iframe identity. The browser suite will use the named group for control reachability without a separate layout-control assertion.

## Risks / Trade-offs

- [Risk] Parent-scoped styles might not reach children rendered by `Dialog`. -> Keep the entire control block lexically in `Workspace` and verify computed layout through the browser suite.
- [Risk] The expanded identifier could change fallback semantics. -> Preserve the current Auto, Focused, Compact, and missing-focused-session cases exactly and run the focused component suite.
- [Risk] Moving controls could reorder actions or remount the iframe. -> Use explicit Close, layout, fullscreen DOM order and keep the keyed dialog and frame structure unchanged.

## Migration Plan

1. Replace `isExpanded` with the reactive `expandedId` derivation.
2. Type the existing children snippet with fullscreen state and toggle behavior, then render the complete control block from `Workspace`.
3. Run Svelte autofix, focused component and browser tests, formatting, linting, type checking, and strict OpenSpec validation.

The change deploys atomically with the frontend bundle and requires no data, protocol, or runtime migration. Rollback restores the previous `isExpanded` helper, dialog-owned Close and fullscreen controls, and separate workspace layout control.

## Open Questions

None.
