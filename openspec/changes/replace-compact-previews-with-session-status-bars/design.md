## Context

Workspace discovery already filters runtime sessions by authoritative `D20.Sessions.Session.phase`, but its public descriptor omits that phase. The Svelte workspace therefore knows only whether the shared workspace channel is ready, stale, or failed and cannot distinguish an active game from a finished one.

Compact mode currently keeps every keyed iframe mounted but gives each compact window a playable-looking `50vw` by `25dvh` surface. That surface is too small for useful game interaction, competes with the application beneath it, and repeats fullscreen alongside actions that remain useful in a compact state. Each newly mounted workspace also initializes its browser-local layout as Auto, which expands the first session returned by discovery even when the same player merely opens another tab or device.

The implementation must preserve the current SDK bridge and iframe node across Auto, Focused, Compact, and browser fullscreen transitions. The supported browser set includes Safari 17.2, which does not support `content-visibility: hidden`.

## Goals / Non-Goals

**Goals:**

- Publish authoritative `in_progress` and `finished` phase values in workspace session descriptors.
- Start every mounted workspace in Compact and expand a session only after an explicit player action.
- Present compact sessions as centered 4rem status bars with 1.5rem badges and controls.
- Give the shared transport state precedence over session phase when deriving Live, Finished, Reconnecting, and Failed labels.
- Present each status as an outlined text badge with supplemental state color and restrained motion.
- Reveal overflowing session identifiers with measured bidirectional motion that respects reduced-motion preferences.
- Keep compact iframe nodes and SDK bridges mounted while removing the game surface from visual rendering, pointer interaction, keyboard navigation, and the accessibility tree.
- Keep multiple compact bars and their Expand, fullscreen, and Close controls reachable within the viewport.
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

4. Compact presentation will be an in-flow 4rem status row inside the existing dialog surface.

   A compact chrome wrapper contains the 1.5rem outlined status badge, a clipped session-identifier lane, and the existing named control group in one flex row. The controls participate in Compact flow, so the flexible identifier lane naturally occupies the space between the badge and controls with equal gaps and no reserved end padding. The same controls remain absolutely positioned over Theater and fullscreen. They use one inline DOM sequence: Close, fullscreen, and Layout, with Layout omitted in fullscreen. CSS changes the group direction and visual order so Compact renders Expand, Enter fullscreen, Close from left to right while Theater renders Close, Compact, Enter fullscreen from top to bottom. Expand uses an unfilled outline square and Compact uses a lower horizontal line. Every control SVG uses the same `0.75rem` square and normalized view-box geometry so Fullscreen and Close have matching visual bounds. The row aligns the badge, identifier, and 1.5rem controls on its block-axis center.

   Alternative considered: create a separate dock component outside the dialog. Keeping one window/dialog subtree preserves identity, focus ownership, and close behavior with less state coordination.

   CSS visual order does not change sequential keyboard navigation, which remains Close, fullscreen, and Layout when all controls are present. This trade-off keeps each button inline and single-source as requested.

5. Compact fullscreen will reveal the game without changing browser-local workspace layout.

   Activating Enter fullscreen from Compact targets the existing dialog surface. While its synchronized `fullscreen` state is true, the status summary is hidden, the game wrapper becomes visible and non-inert, and the normal fullscreen Close and Exit fullscreen controls render. Exiting fullscreen makes the same entry compact again because no `workspace.focus` operation occurred.

   Alternative considered: focus the session before requesting fullscreen. That would change the saved local layout and return to Theater rather than the Compact bar after fullscreen exits.

6. Overflowing session identifiers will use container-relative CSS motion.

   The identifier lane becomes an inline-size query container. Its max-content text animates between zero and `min(0px, calc(100cqi - 100%))`: `100cqi` is the lane width and `100%` is the text width, so fitting text resolves to zero while overflowing text resolves to the exact negative difference. Each iteration lasts 5.8333 seconds, which increases speed by 20% relative to the original 7-second iteration. CSS pauses the animation while the identifier itself is hovered and disables it when `prefers-reduced-motion: reduce` matches. Focus on the adjacent window controls does not pause identifier motion.

   Alternative considered: ResizeObserver plus Web Animations, a fixed CSS translation, or deprecated `marquee`. JavaScript is unnecessary because supported container-query units express the exact distance; a fixed distance either clips or over-travels, while `marquee` has obsolete semantics and no acceptable motion control.

7. Status motion and color will remain supplemental.

   The badge always renders the agreed status text in uppercase inside a neutral ghost-style outline. Live uses a green dot with a 1.2-second opacity pulse. Reconnecting keeps warning-colored text and uses a warning-colored dot with a faster 0.8-second opacity pulse to distinguish active recovery from a healthy connection. Failed keeps neutral text with a static error-colored dot, while Finished keeps neutral text and a static neutral dot. Reduced-motion disables both pulses without removing text or state color, and both rates remain far below three flashes per second.

   Alternative considered: replace text with only a colored dot. That would make state depend on color and animation and reduce accessibility.

8. The compact collection will remain a single viewport-bounded stack.

   The fixed lower-end container will use one responsive column, a bounded inline size, available viewport block size, and scrolling when the number of bars exceeds the viewport. Every compact grid row and window has a 4rem block size. Adjacent rows use a 0.375rem gap, half the original 0.75rem gap. Compact windows override the dialog surface shadow to `none` through an inherited component custom property, while Theater retains the dialog's default elevation.

   Alternative considered: preserve the auto-fit preview grid. Multiple narrow status bars are easier to scan and operate as a single stack, especially on mobile and at text zoom.

9. Browser-local workspace layout will initialize in Compact.

   `createWorkspace/0` will initialize its local layout store with `{mode: "compact"}`. Complete workspace snapshots can add, remove, or replace session descriptors without selecting a Theater window. Activating Expand remains the only normal path to `{mode: "focused", id}`, and a newly mounted component creates a fresh Compact layout even when the same actor has sessions open elsewhere.

   The existing `auto` layout variant and resolution branch will remain available to avoid unrelated interface churn, but it will no longer be the store's initial state.

   Alternative considered: keep Auto and compact only the first received snapshot. That introduces snapshot-order state and can expand a later session after an empty initial response, while initializing the local store directly expresses the intended invariant.

## Risks / Trade-offs

- [Risk] A hidden iframe could still receive focus or assistive-technology navigation. -> Make the game wrapper inert in Compact, hide it for all supported browsers, and verify the frame is not visible while the status controls remain reachable.
- [Risk] `content-visibility: hidden` is unavailable in Safari 17.2. -> Use `display: none` as the baseline and enable `content-visibility` only behind `@supports`; both keep the DOM node mounted.
- [Risk] Adding a required descriptor field can break an independently deployed stale frontend. -> Deploy backend and frontend atomically as one Phoenix release and keep the field additive on the wire.
- [Risk] Persistent identifier, Live, or Reconnecting motion could distract users. -> Animate only actual overflow and active transport states, pause identifier motion during inspection, keep status pulses restrained, and disable all motion under reduced-motion preferences.
- [Risk] A compact row could crowd long status text and controls. -> Keep the 1.5rem status and controls non-shrinking, give the identifier the only flexible clipped lane, and verify minimum-viewport geometry in a real browser.
- [Risk] Smaller controls can fall below comfortable touch-target guidance. -> Keep the requested 1.5rem square as the lower bound, preserve focus styling and accessible labels, and verify keyboard and pointer operation in a real browser.
- [Risk] CSS visual order differs from the fixed Close, fullscreen, Layout DOM and sequential-focus order. -> Keep the source order stable and document the deliberate trade-off; restore state-specific DOM order if visual and keyboard order must align again.
- [Risk] Fullscreen entered from Compact could remain inert or return to Theater. -> Derive game visibility from `expanded || fullscreen` and do not mutate workspace layout when toggling fullscreen.
- [Risk] Many compact sessions can exceed viewport height. -> Bound the stack by dynamic viewport height and keep its scrollbar usable.
- [Risk] A dialog surface shadow can visually fill the compact row gap. -> Disable surface elevation only for Compact windows and preserve the default shadow for Theater.
- [Risk] Reconnect or replacement snapshots could accidentally restore Auto expansion. -> Keep layout state independent from channel snapshots and cover initial, replacement, and remount behavior in focused tests.

## Migration Plan

1. Publish `phase` in workspace snapshots and cover initial and transition snapshots in channel tests.
2. Separate internal session descriptors and runtime PIDs from the channel-owned public snapshot envelope.
3. Require `phase` in the frontend descriptor and update test fixtures.
4. Initialize browser-local layout in Compact and preserve explicit focus behavior.
5. Replace compact preview rendering and geometry with the centered 4rem status row, hidden stable game wrapper, 1.5rem badge, identifier motion, and compact control variant.
6. Reveal the game for Compact fullscreen without changing workspace layout.
7. Verify default Compact mounting, status precedence, iframe/bridge identity, accessibility exposure, motion preferences, responsive geometry, stacking, and Theater/fullscreen behavior.

The Phoenix release deploys the additive snapshot field and consuming frontend bundle together. No data migration is required. Rollback restores both sides together; running sessions and embedded module state are unaffected.

## Open Questions

None.
