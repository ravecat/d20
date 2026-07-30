## Context

Workspace discovery already filters runtime sessions by authoritative `D20.Sessions.Session.phase`, but its public descriptor omits that phase. The Svelte workspace therefore knows only whether the shared workspace channel is ready, stale, or failed and cannot distinguish an active game from a finished one.

Compact mode currently keeps every keyed iframe mounted but gives each compact window a playable-looking `50vw` by `25dvh` surface. That surface is too small for useful game interaction, competes with the application beneath it, and repeats fullscreen alongside actions that remain useful in a compact state. Each newly mounted workspace also initializes its browser-local layout as Auto, which expands the first session returned by discovery even when the same player merely opens another tab or device.

The implementation must preserve the current SDK bridge and iframe node across Auto, Focused, Compact, and browser fullscreen transitions. The supported browser set includes Safari 17.2, which does not support `content-visibility: hidden`.

## Goals / Non-Goals

**Goals:**

- Publish authoritative `in_progress` and `finished` phase values in workspace session descriptors.
- Start every mounted workspace in Compact and expand a session only after the player activates its Compact restore surface.
- Present compact sessions as centered content-sized status bars with 1.875rem badges and window controls.
- Give the shared transport state precedence over session phase when deriving Live, Finished, Reconnecting, and Failed labels.
- Present each status as a white text badge with theme-content text, supplemental state color, and restrained motion.
- Reveal overflowing session identifiers with measured bidirectional motion that respects reduced-motion preferences.
- Keep compact iframe nodes and SDK bridges mounted while removing the game surface from visual rendering, pointer interaction, keyboard navigation, and the accessibility tree.
- Keep multiple compact bars, their restore surfaces, and their fullscreen and Close controls reachable within the viewport.
- Let browser fullscreen reveal the mounted game directly from Compact and restore Compact after exit.
- Preserve existing Theater and browser-fullscreen behavior.

**Non-Goals:**

- Add per-game or per-iframe connection monitoring.
- Add reconnect or retry controls.
- Change session lifecycle, membership, close acknowledgement, module tokens, iframe URLs, sandboxing, or SDK protocol.
- Show game-specific titles reconstructed from slugs.
- Rename the agreed Live, Finished, Reconnecting, or Failed status labels.
- Make the compact status-bar surface itself playable.
- Introduce a new workspace state machine or persistence model.

## Decisions

1. The backend workspace descriptor will include the session phase already used for discovery, while the channel will own the public snapshot envelope.

   `D20Web.Workspace.sessions/1` will pass the matched phase into descriptor construction and return `{descriptors, runtime_pids}`. `runtime_pids` will be a `MapSet` because the channel needs only process identity for monitor reconciliation. `D20Web.WorkspaceChannel` will construct `%{sessions: descriptors}` before returning or pushing the unchanged public snapshot. The frontend wire type will require the same two phase values, `in_progress` and `finished`.

   Alternative considered: infer Finished from the game projection or a separate session controller. That would duplicate subscriptions and violate the workspace snapshot's role as the authoritative discovery read model.

   Alternative considered: return `%{sessions: descriptors}` together with `%{pid => session_id}` from `D20Web.Workspace`. That embeds a transport envelope in session discovery and retains session-id values unused by monitor reconciliation.

2. Compact status will be derived during rendering with transport precedence.

   Failed workspace transport maps to Failed, stale or another non-ready retained transport maps to Reconnecting, ready plus `finished` maps to Finished, and ready plus `in_progress` maps to Live. Initial loading has no discovered sessions in production, so it does not need a fifth compact status.

   Alternative considered: store a status on each descriptor. Connection state is shared and ephemeral, so storing the combined value would duplicate derived client state and blur the backend/client boundary.

3. Every keyed workspace entry will keep one stable game-frame subtree.

   `Workspace` will always render the same `Frame` component inside a dedicated game-surface wrapper. The wrapper is visible when the session is the Theater window or its dialog surface is in browser fullscreen. Otherwise, Compact makes the wrapper inert and hidden. The baseline CSS uses `display: none`; browsers that support `content-visibility: hidden` can use it instead without detaching or reparenting the iframe.

   Alternative considered: conditionally render `Frame`. That would destroy the SDK bridge and reload the embedded game whenever layout changes. Moving the iframe between separate compact and expanded containers would also create avoidable DOM-lifecycle risk.

4. Compact presentation will be an in-flow content-sized status row inside the existing dialog surface.

   A Compact chrome wrapper contains the 1.875rem outlined status badge, clipped session-identifier lane, and named control group as direct flex children. A separate empty native restore button is a sibling overlay spanning the row behind those visible children, so activating the non-control surface restores that session to Theater without drawing a button box around the status and identifier. The Compact control group contains only Close and fullscreen in source order, with CSS presenting fullscreen before Close at the logical end above the restore layer. This avoids nested interactive content, and fullscreen or Close activation cannot bubble into restoration. Compact chrome uses 0.5rem padding on both axes, and the grid row and window derive their block size from that chrome instead of imposing a fixed height.

   Theater and fullscreen keep their absolutely positioned controls. Theater uses one inline DOM sequence of Close, fullscreen, and Layout, with CSS presenting Close, Compact, and Enter fullscreen from top to bottom; fullscreen omits Layout. Compact, Theater, and fullscreen share `1.875rem` controls and `0.9375rem` SVGs from the base window-control rules, so changing presentation mode does not resize the actions. The Compact row aligns the badge, identifier, and controls on its block-axis center.

   Compact windows invert the dialog surface through component custom properties: the theme content color becomes the surface background. Session identifiers use pure white. Status badges use a pure-white background and theme-content text, with a 5.25rem minimum inline size that makes the default Live badge approximately 50% wider while still allowing longer labels to grow. Compact controls invert against the surface, using the theme base color as their background and the theme content color for their icons. Theater and fullscreen keep their existing surface and control colors.

   Alternative considered: create a separate dock component outside the dialog. Keeping one window/dialog subtree preserves identity, focus ownership, and close behavior with less state coordination.

   Alternative considered: attach pointer and keyboard handlers to the whole row while leaving controls inside it. That would require custom button semantics around nested native buttons and would make action isolation fragile.

   CSS visual order does not change sequential keyboard navigation. Compact visits the restore surface, Close, and fullscreen in DOM order, while Theater remains Close, fullscreen, and Layout. The restore button has no visual box of its own; its `:focus-visible` state draws the keyboard indicator on the whole Compact chrome. This trade-off keeps every action native and avoids custom focus reordering.

5. Compact fullscreen will reveal the game without changing browser-local workspace layout.

   Activating Enter fullscreen from Compact targets the existing dialog surface. While its synchronized `fullscreen` state is true, the status summary is hidden, the game wrapper becomes visible and non-inert, and the normal fullscreen Close and Exit fullscreen controls render. Exiting fullscreen makes the same entry compact again because no `workspace.focus` operation occurred.

   Alternative considered: focus the session before requesting fullscreen. That would change the saved local layout and return to Theater rather than the Compact bar after fullscreen exits.

6. Overflowing session identifiers will use container-relative CSS motion.

   The identifier lane becomes an inline-size query container. Its max-content text animates between zero and `min(0px, calc(100cqi - 100%))`: `100cqi` is the lane width and `100%` is the text width, so fitting text resolves to zero while overflowing text resolves to the exact negative difference. Each iteration lasts 5.8333 seconds, which increases speed by 20% relative to the original 7-second iteration. CSS pauses the animation while the identifier itself is hovered and disables it when `prefers-reduced-motion: reduce` matches. Focus on the adjacent window controls does not pause identifier motion.

   Alternative considered: ResizeObserver plus Web Animations, a fixed CSS translation, or deprecated `marquee`. JavaScript is unnecessary because supported container-query units express the exact distance; a fixed distance either clips or over-travels, while `marquee` has obsolete semantics and no acceptable motion control.

7. Status motion and color will remain supplemental.

   The badge always renders the agreed status text in uppercase as theme-content text on a white background. Live uses a green dot with a 1.2-second opacity pulse. Reconnecting uses a warning-colored dot with a faster 0.8-second opacity pulse to distinguish active recovery from a healthy connection. Failed uses a static error-colored dot, while Finished uses a static neutral dot. Reduced-motion disables both pulses without removing text or state color, and both rates remain far below three flashes per second.

   Alternative considered: replace text with only a colored dot. That would make state depend on color and animation and reduce accessibility.

8. The compact collection will remain a single viewport-bounded stack.

   The fixed lower-end container will use one responsive column, a bounded inline size, available viewport block size, and scrolling when the number of bars exceeds the viewport. Every compact grid row and window derives its block size from the 1.875rem controls and equal 0.5rem chrome padding. Adjacent rows use a 0.375rem gap, half the original 0.75rem gap. Compact windows override the dialog surface shadow to `none` through an inherited component custom property, while Theater retains the dialog's default elevation.

   Alternative considered: preserve the auto-fit preview grid. Multiple narrow status bars are easier to scan and operate as a single stack, especially on mobile and at text zoom.

9. Browser-local workspace layout will initialize in Compact.

   `createWorkspace/0` will initialize its local layout store with `{mode: "compact"}`. Complete workspace snapshots can add, remove, or replace session descriptors without selecting a Theater window. Activating a session's Compact restore surface remains the only normal path to `{mode: "focused", id}`, and a newly mounted component creates a fresh Compact layout even when the same actor has sessions open elsewhere.

   The existing `auto` layout variant and resolution branch will remain available to avoid unrelated interface churn, but it will no longer be the store's initial state.

   Alternative considered: keep Auto and compact only the first received snapshot. That introduces snapshot-order state and can expand a later session after an empty initial response, while initializing the local store directly expresses the intended invariant.

## Risks / Trade-offs

- [Risk] A hidden iframe could still receive focus or assistive-technology navigation. -> Make the game wrapper inert in Compact, hide it for all supported browsers, and verify the frame is not visible while the status controls remain reachable.
- [Risk] `content-visibility: hidden` is unavailable in Safari 17.2. -> Use `display: none` as the baseline and enable `content-visibility` only behind `@supports`; both keep the DOM node mounted.
- [Risk] Adding a required descriptor field can break an independently deployed stale frontend. -> Deploy backend and frontend atomically as one Phoenix release and keep the field additive on the wire.
- [Risk] Persistent identifier, Live, or Reconnecting motion could distract users. -> Animate only actual overflow and active transport states, pause identifier motion during inspection, keep status pulses restrained, and disable all motion under reduced-motion preferences.
- [Risk] A compact row could crowd long status text and enlarged controls. -> Keep the 1.875rem status and controls non-shrinking, use equal 0.5rem padding, give the identifier the only flexible clipped lane, and verify the content-sized row at the minimum viewport in a real browser.
- [Risk] The row-spanning restore surface could intercept fullscreen or Close. -> Keep the restore button below the visible content layer, place the named controls above it, and cover each action independently with pointer and keyboard tests.
- [Risk] CSS visual order differs from the fixed source and sequential-focus order. -> Keep the source order stable within each state and document the deliberate trade-off; restore state-specific visual order if visual and keyboard order must align again.
- [Risk] Fullscreen entered from Compact could remain inert or return to Theater. -> Derive game visibility from `expanded || fullscreen` and do not mutate workspace layout when toggling fullscreen.
- [Risk] Many compact sessions can exceed viewport height. -> Bound the stack by dynamic viewport height and keep its scrollbar usable.
- [Risk] A dialog surface shadow can visually fill the compact row gap. -> Disable surface elevation only for Compact windows and preserve the default shadow for Theater.
- [Risk] Inverting the Compact palette could reduce legibility in a custom theme. -> Use the existing paired base and content theme tokens in opposite roles and verify the computed contrast in the active browser.
- [Risk] A wider status badge could crowd the identifier on narrow viewports. -> Apply 5.25rem as a minimum rather than a fixed size, keep the identifier as the only shrinking lane, and verify both controls remain reachable without horizontal overflow.
- [Risk] Reconnect or replacement snapshots could accidentally restore Auto expansion. -> Keep layout state independent from channel snapshots and cover initial, replacement, and remount behavior in focused tests.

## Migration Plan

1. Publish `phase` in workspace snapshots and cover initial and transition snapshots in channel tests.
2. Separate internal session descriptors and runtime PIDs from the channel-owned public snapshot envelope.
3. Require `phase` in the frontend descriptor and update test fixtures.
4. Initialize browser-local layout in Compact and preserve explicit focus behavior.
5. Replace compact preview rendering and geometry with the centered content-sized status row, hidden stable game wrapper, 1.875rem badge, identifier motion, restore surface, and compact control variant.
6. Reveal the game for Compact fullscreen without changing workspace layout.
7. Verify default Compact mounting, status precedence, iframe/bridge identity, accessibility exposure, motion preferences, responsive geometry, stacking, and Theater/fullscreen behavior.

The Phoenix release deploys the additive snapshot field and consuming frontend bundle together. No data migration is required. Rollback restores both sides together; running sessions and embedded module state are unaffected.

## Open Questions

None.
