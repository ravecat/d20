## Context

`Session` owns the realtime session state and mounts the embedded game for `in_progress` and `finished` phases. It receives the module identifier from the game page for the player's accessible name. `Frame` owns the iframe and D20 SDK bridge. The active game detail layout change already requires this frame to remain mounted above the page, but it does not define multiple display modes or native fullscreen behavior.

The current frontend work introduces a `Dialog` presentation boundary around `Frame`. That interaction needs a durable contract before its dimensions and controls are refined. The design must preserve the iframe DOM node and SDK bridge across presentation changes because remounting can reload the game, reset iframe-local UI state, and reconnect the bridge.

Browser behavior is a constraint. A modal HTML dialog provides a top-layer backdrop and focus boundary, while a non-modal dialog permits interaction with the page. Theater delegates backdrop hit testing to native `closedby="any"` light dismiss, then the shell intercepts the resulting close request and changes display mode instead of closing the game. Browsers without `closedby` support retain the explicit Compact control and Escape transition but do not get backdrop light dismiss. The Fullscreen API accepts ordinary HTML elements but rejects a `dialog` element as the fullscreen target, and the browser remains free to deny a request or retain navigation UI.

## Goals / Non-Goals

**Goals:**

- Define Theater as the default presentation for every mounted embedded game.
- Define Compact as a non-modal corner presentation reached without closing or reloading the game.
- Define native fullscreen for the complete player surface when the browser supports it.
- Keep one iframe and one SDK bridge alive across all presentation transitions.
- Preserve accessible controls, keyboard behavior, responsive bounds, and safe-area insets.
- Preserve existing session lifecycle and iframe module contracts.

**Non-Goals:**

- Change game rules, projections, channel messages, routes, persistence, or module sandbox policy.
- Change layout or behavior inside a separately deployed iframe game.
- Guarantee that a browser hides its own chrome or grants fullscreen.
- Add drag, resize, picture-in-picture, a separate browser window, or persisted mode preference.
- Add a command that unmounts or permanently closes the active game surface.

## Decisions

1. Keep presentation behavior in `Dialog` and transport behavior in `Frame`.

   `Dialog` owns mode state, dialog lifecycle, fullscreen state, controls, and player sizing. `Frame` remains a full-size iframe plus SDK bridge. This boundary lets presentation change without duplicating or reconnecting the module transport.

   Alternative considered: keep overlay and fullscreen logic in `Frame`. That couples browser presentation state to the iframe bridge and makes accidental remounts more likely.

2. Use one dialog element for Theater and Compact modes.

   Theater opens the dialog with `showModal()` so it is in the top layer with a backdrop and modal focus behavior. Compact reopens the same element with `show()` and positions it at the viewport's bottom-end corner without a backdrop or page blocking. Mode transitions close and reopen the dialog element but never conditionally remove its player or iframe children.

   Theater backdrop activation and Escape mean "switch to Compact", not "close the game". Theater therefore declares `closedby="any"`, and Compact removes the attribute because it is non-modal. The browser owns backdrop hit testing and emits a close request. The `cancel` event is prevented and changes the Svelte mode state, so the effect closes the modal presentation and reopens the same element with `show()` without unmounting its children.

   The Svelte `mode` value is the only source of truth for Theater and Compact. One effect closes the previous dialog presentation, opens the presentation for the current mode, and closes the element during component cleanup. This avoids splitting dialog ownership between event handlers and lifecycle effects.

   Alternative considered: implement both modes as fixed `div` overlays. That loses native modal semantics, focus handling, Escape integration, and `::backdrop`.

3. Request fullscreen on the player wrapper.

   The player wrapper contains the iframe, controls, and error feedback, so making it the fullscreen element keeps the game and its exit control together. The `dialog` itself is not a valid Fullscreen API target. A direct user action calls `requestFullscreen({ navigationUI: "hide" })`; `fullscreenchange` and `document.fullscreenElement` remain the source of truth for entered and exited state. A declarative Svelte document event binding owns the listener for exactly the component lifetime.

   Fullscreen is progressive enhancement. The control does not preflight browser support: an unavailable method, a synchronous failure, or a rejected request is absorbed at the request boundary. Failure leaves the current Theater or Compact mode intact without presenting an application error. The navigation UI option is a preference, not a guarantee.

   Alternative considered: apply CSS viewport dimensions and call that fullscreen. That only fills the browser viewport and does not request system-level fullscreen.

4. Preserve the display mode while entering and exiting fullscreen.

   Fullscreen is an orthogonal browser state, not a third dialog mode. Exiting fullscreen returns to whichever of Theater or Compact was active before entry. Mode controls are hidden while fullscreen is active, while the fullscreen control changes to an exit action. A dialog cancel event received during fullscreen is prevented without changing the stored mode.

   Alternative considered: always return to Theater after fullscreen. That discards the user's explicit Compact choice and introduces an unrelated mode transition.

5. Keep session lifecycle as the mount boundary.

   `Session` continues to mount the game only when the realtime phase is `in_progress` or `finished`. Loading and waiting phases do not mount it. Presentation state is local to `Dialog` and does not enter session state or public projections.

   Alternative considered: persist the mode in the session. Display mode is per-viewer, ephemeral UI state and has no authoritative game meaning.

6. Bound both modes to the dynamic viewport.

   Theater uses a centered, game-friendly maximum size constrained by dynamic viewport width and height. Compact uses a smaller bounded surface anchored to the bottom-end safe area. Narrow screens reduce the outer inset and allow Theater to occupy nearly all available space while keeping Compact within the visible viewport.

   Alternative considered: fixed pixel dimensions. They overflow small devices and waste space on large displays.

## Risks / Trade-offs

- [`closedby` support is not universal] - Treat backdrop light dismiss as progressive enhancement and retain the explicit Compact control plus Escape close-request handling without a pointer-coordinate fallback.
- [Imperative dialog state can drift from Svelte state] - Keep `mode` as the only source of truth and centralize close, modal open, non-modal open, and cleanup in one effect.
- [Fullscreen can be unavailable or denied by browser policy, iframe embedding policy, or missing user activation] - Invoke only from a button action, absorb failure at the request boundary, and preserve the current mode.
- [The browser can exit fullscreen independently] - Derive state from `document.fullscreenElement` on every `fullscreenchange` rather than trusting the last button action.
- [Changing between modal and non-modal states changes focus behavior] - Keep controls in stable DOM order and verify focus, Escape, and page interaction in both modes.
- [Keyboard events inside a focused cross-origin iframe do not bubble to the host document] - Treat host Escape handling as progressive behavior when the browser sends a close request to the parent dialog, retain explicit visible mode controls, and require iframe protocol cooperation before promising Escape from inside every embedded game.
- [A large iframe is expensive to reload] - Keep the iframe mounted and verify bridge initialization occurs once across transitions.

## Migration Plan

1. Finalize the display-mode requirements and open product decisions in this change.
2. Align `Dialog`, `Frame`, and `Session` with the accepted contract, including native backdrop light dismiss and controlled close-request transitions.
3. Extend focused component tests for lifecycle, mode transitions, fullscreen state, failures, accessibility, and iframe continuity.
4. Run frontend formatting, tests, and type checks, then verify desktop and narrow layouts in a real browser.
5. Roll back by restoring the previous fixed overlay wrapper. No backend or data rollback is required.

## Open Questions

- Should a viewer's Compact or Theater choice survive page reloads for the same session?
- Should Compact later support dragging or resizing, or remain a fixed bottom-end window?
- Does the active game surface need an explicit close or return-to-page action in addition to Compact mode?
- Should the exact Theater and Compact dimensions become design tokens after the interaction is approved?
