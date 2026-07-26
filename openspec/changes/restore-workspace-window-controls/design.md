## Context

`assets/js/components/dialog.svelte` owns the shell overlay for each embedded game. Workspace state already exposes `compact(sessionId)` and passes it to the dialog as `onCompact`, but the component currently renders a mode action only when `mode === "compact"`. Theater therefore has no visible Compact action even though Escape and native dialog close requests can still invoke the same transition.

The component also renders Expand before Close in Compact mode and uses the default horizontal flex direction. This makes DOM, keyboard, and visual order differ from the requested hierarchy. The iframe is a child of the same dialog surface and must remain mounted while only workspace mode changes.

`assets/js/components/workspace.svelte` also composes a passive `WorkspaceDock` after the game-window collection. The dock repeats each session's name, shortened identifier, connection status, and mode, but has no controls. The window collection reserves additional bottom space for this dock in desktop and mobile layouts.

The Compact window collection currently spans almost the full viewport inline size, and `dialog--compact` fills the available grid track. A single preview therefore becomes a broad strip across the bottom of the page. The requested reference instead marks the lower-right half of the bottom quarter, corresponding to a target of approximately `50vw` by `25dvh`, or one eighth of the viewport area.

## Goals / Non-Goals

**Goals:**

- Expose the existing `onCompact` transition from Theater mode.
- Make Close the first control in DOM, keyboard, and visual order.
- Place the applicable mode action second and fullscreen action last.
- Render the control group as one vertical column without changing button geometry or top-end placement.
- Preserve native button semantics, accessible names, focus visibility, iframe identity, and SDK bridge identity.
- Remove the passive workspace session dock and its duplicate metadata without a replacement panel.
- Reclaim the dock-only block-end reservation while preserving the safe-area offset.
- Bound the wide-viewport Compact preview region to approximately `50vw` by `25dvh` at the lower-right safe-area edge.
- Keep a narrow-viewport fallback that prioritizes reachable controls and avoids horizontal viewport overflow.
- Cover the action matrix, semantic order, and Theater-to-Compact continuity in the focused workspace component test, and verify the vertical layout in a real browser.

**Non-Goals:**

- Change workspace state types, persistence, session lifecycle, or close semantics.
- Change Escape, backdrop light dismiss, or Fullscreen API behavior.
- Expose a Compact or Expand action while browser fullscreen is active.
- Redesign button size, colors, spacing, focus treatment, or edge offsets.
- Change iframe module contracts or the separately delivered game UI.
- Change active-session discovery, reconciliation, mounting, or connection-status behavior.
- Add a replacement taskbar, switcher, status panel, or session-management surface.
- Change Theater or browser fullscreen dimensions.
- Change the embedded game's own responsive layout or zoom behavior.

## Decisions

1. Put semantic order in the markup.

   Close will render first. Outside browser fullscreen, the component will then render exactly one mode action selected from the current workspace mode. The fullscreen action will remain last. DOM order will therefore produce the same reading, tab, and visual sequence without CSS `order`.

   Alternative considered: retain markup order and use CSS `order`. That would change only visual order and leave keyboard and assistive-technology traversal inconsistent with the requested hierarchy.

2. Reuse the existing workspace mode callback.

   Theater will render a native button named `Compact <label>` whose click handler is `onCompact`. Compact will retain its existing `Expand <label>` action. No local mode state or second transition path will be introduced.

   Alternative considered: close the dialog imperatively and depend on `onclose` to compact it. That would route an explicit display action through native close side effects and make the transition depend on dialog event timing.

3. Keep mode actions hidden during browser fullscreen.

   The Fullscreen API preserves the underlying Theater or Compact mode. While fullscreen is active, the group will expose Close followed by Exit fullscreen. Exiting fullscreen restores the applicable mode action because the existing `fullscreenchange` synchronization updates component state.

   Alternative considered: expose Compact inside browser fullscreen. This would combine two presentation transitions in one action and expand the change beyond the reported missing Theater control.

4. Use a named control group and one-column flex layout.

   The existing control container will receive `role="group"` so its label has defined accessibility semantics. `flex-direction: column` will turn the existing top-end flex overlay into a single vertical column while retaining the current `0.3rem` gap, `0.4rem` edge offsets, and `2rem` button geometry.

   Alternative considered: CSS Grid with one column. Flex already owns this linear group, so Grid would add no behavior or layout advantage.

5. Split behavioral and presentation verification at their effective boundaries.

   The existing Vitest and jsdom workspace test will inspect buttons through their accessible names inside the named group, assert the explicit DOM order for each mode, activate Theater-to-Compact directly, and verify that the iframe and SDK bridge are retained. A real-browser inspection will verify the computed column direction and focus presentation because the repository intentionally does not process scoped component CSS in jsdom.

   Alternative considered: re-enable scoped CSS processing in Vitest. The repository previously removed computed-style assertions so component tests remain focused on observable behavior; restoring special test configuration for one declaration would reintroduce that coupling.

6. Remove the dock at the workspace composition boundary.

   `WorkspaceDock` will be removed from `workspace.svelte`, and the obsolete component will be deleted. The mounted keyed `GameWindow` collection remains the only representation of active sessions, so discovery, reconciliation, iframe identity, and window actions are unchanged.

   Alternative considered: hide the dock with CSS. That would leave duplicate semantics and dead component logic in the document or bundle and would preserve an unnecessary implementation boundary.

7. Reclaim only the space that belonged to the dock.

   The window collection will retain its existing logical safe-area inset but drop the additional desktop and mobile block-end offsets that reserved room for the dock. No other window dimensions or positioning rules change.

   Alternative considered: keep the existing offsets. That would leave a visible empty strip and make the removed panel continue to influence layout.

8. Bound the Compact region instead of resizing embedded games individually.

   Above the existing `48rem` responsive boundary, the workspace Compact region will use a target inline size of `50vw` and block size of `25dvh`, aligned to the logical inline-end and block-end safe-area edges. A minimum block size of `8rem` protects the vertical control stack on unusually short viewports. A single Compact dialog fills that region; multiple Compact dialogs remain within the same bounded, scrollable region. At `48rem` and below, the region may use the available inline width so the iframe and vertical controls remain usable.

   Alternative considered: give every Compact dialog fixed viewport dimensions independently. That would make multiple sessions overlap or expand the total overlay beyond the requested footprint.

   Alternative considered: apply the one-eighth footprint on every viewport. Half of a narrow mobile viewport would make the game and its controls impractical, so the existing responsive boundary remains the explicit fallback point.

## Risks / Trade-offs

- [Risk] Three vertical controls cover more block-axis game content than the current horizontal group. - Mitigation: preserve the reduced `2rem` control size and `0.3rem` gap, keep the group at the top-end edge, and verify the supported viewport behavior.
- [Risk] The new mode button could trigger a dialog close event that compacts twice. - Mitigation: call the existing workspace callback directly and retain keyed workspace entries so the same dialog and iframe are updated declaratively.
- [Risk] A CSS regression can preserve semantic order while breaking the vertical presentation. - Mitigation: verify computed `flex-direction`, action order, and focus presentation in a real browser while component tests protect the behavioral contract.
- [Risk] Removing the dock removes an at-a-glance session count and connection summary. - Mitigation: the panel exposes no action and duplicates mounted windows; preserve each window's existing status and recovery presentation, and treat any future session switcher as a separately specified capability.
- [Risk] Several Compact windows have less visible space inside the bounded region. - Mitigation: retain the existing scrollable collection and verify that each window and its controls remain reachable.
- [Risk] Viewport units can include browser chrome differently across devices. - Mitigation: use dynamic viewport block units, retain safe-area offsets, and verify the wide and narrow responsive branches in a real browser.

## Migration Plan

1. Add focused component coverage for the expected action matrix, order, and Theater-to-Compact continuity.
2. Reorder the semantic buttons, add the Theater Compact branch, name the control group, and switch its flex direction to column.
3. Run focused tests, formatting, frontend lint, type checks, and strict OpenSpec validation.
4. Remove the workspace dock, delete its component, and reduce the game-window block-end inset to the safe-area offset.
5. Verify in component tests and a real browser that no duplicate panel remains and every active game window stays mounted and controllable.
6. Add wide-viewport coverage for a lower-right `50vw` by `25dvh` Compact region and narrow-viewport coverage for reachable controls without horizontal overflow.
7. Constrain the Compact collection and preview height at the workspace presentation boundary without changing Theater or fullscreen sizing.
8. Roll back by restoring the former conditional control markup, horizontal layout, full-width Compact region, dock composition, dock component, and reserved offsets; no data migration or coordinated deployment is required.

## Open Questions

- None. Issues #76 and #77 plus the supplied viewport reference define the control correction, panel removal, and Compact footprint.
