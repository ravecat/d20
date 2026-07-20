## 1. Component Boundaries and Lifecycle

- [x] 1.1 Add `Dialog` as the owner of embedded game presentation and keep `Frame` limited to the iframe and D20 SDK bridge.
- [x] 1.2 Mount `Dialog` from `Session` only for `in_progress` and `finished` realtime phases.
- [x] 1.3 Preserve the existing module configuration and cloneable connection bootstrap passed to the SDK bridge, and use the module identifier as the dialog's accessible name.

## 2. Theater and Compact Modes

- [x] 2.1 Open each mounted player in centered modal Theater mode with a backdrop and responsive dynamic-viewport bounds.
- [x] 2.2 Add explicit Compact and Theater controls and render Compact as a bounded non-modal bottom-end window.
- [x] 2.3 Enable native `closedby="any"` light dismiss in Theater and handle its backdrop and Escape close requests as controlled Compact mode transitions.
- [x] 2.4 Make Svelte mode state the single owner of dialog presentation and use declarative document event binding for fullscreen synchronization.
- [x] 2.5 Verify focus handoff, page interaction in Compact mode, safe-area offsets, and narrow-viewport bounds.

## 3. Native Fullscreen

- [x] 3.1 Request fullscreen on the complete player wrapper from a direct user action and retain the current Theater or Compact mode.
- [x] 3.2 Synchronize the enter and exit control from `fullscreenchange` and `document.fullscreenElement`.
- [x] 3.3 Keep the fullscreen action available and absorb failures without changing the current display mode.

## 4. Continuity and Validation

- [x] 4.1 Cover default Theater mode, Theater-to-Compact-to-Theater transitions, native fullscreen entry and exit, stable iframe identity, and single bridge initialization in focused component tests.
- [x] 4.2 Extend focused component tests for the Theater `closedby` contract, controlled close-request transitions, silently unavailable or rejected fullscreen, and browser-driven fullscreen exit.
- [x] 4.3 Run `bun run test -- js/components/session.test.ts` from `assets/`, then run `mix assets.lint`, `mix assets.test`, and `mix typecheck` after implementation aligns with the finalized specification.
- [x] 4.4 Verify Theater, Compact, backdrop, keyboard, and fullscreen behavior at desktop and narrow widths in a real browser.
- [x] 4.5 Run strict OpenSpec validation and record any browser-specific limitation that remains after visual verification.
