## Context

`auth_dialog.svelte` opens a native `<dialog>` with `showModal()` and styles its generated `::backdrop`. Backdrop activation is currently detected by listening for every click on the dialog, comparing the pointer coordinates with `getBoundingClientRect()`, and closing only when the coordinates fall outside the dialog box.

The referenced NoLoJS recipe uses `<dialog popover>` to obtain automatic light dismissal and a CSS backdrop. That is appropriate for non-modal content, as used by the Koala Rescue Club result popup, but a popover does not make the underlying page inert or provide the modal focus boundary required for account credentials. D20 already uses `closedby="any"` as progressive enhancement for another modal dialog.

## Goals / Non-Goals

**Goals:**

- Delegate modal backdrop hit testing and light dismissal to the browser.
- Preserve native modal focus containment, Escape dismissal, explicit close, focus restoration, and CSS backdrop styling.
- Remove pointer-coordinate and dialog-bound calculations from the shared account dialog.
- Keep supported browsers without `closedby` usable through Escape and the visible close action.

**Non-Goals:**

- Convert the authentication surface to a non-modal popover.
- Add a JavaScript fallback for native light dismissal.
- Change dialog layout, account forms, routes, authentication state, or return behavior.
- Expand the browser-support policy or add a polyfill.

## Decisions

### Keep a modal dialog and declare native light dismissal

The existing `<dialog>` remains opened with `showModal()` and receives `closedby="any"`. Supporting browsers then own backdrop hit testing, close requests, and dismissal. The existing `close` event continues to synchronize the bound `open` state and restore focus.

Using the NoLoJS `<dialog popover>` recipe directly was rejected because popovers are non-modal and leave the application behind the credential form interactive. A separate full-viewport clickable element was rejected because it would recreate browser overlay behavior in application markup.

### Treat light dismissal as progressive enhancement

The project's Baseline Widely Available target still includes Safari versions without `closedby`. Those browsers retain the existing explicit close button and native Escape handling but do not receive backdrop light dismissal. This matches the existing D20 Theater decision and avoids maintaining a second hit-testing implementation.

Keeping the coordinate fallback was rejected because it is the complexity being removed and makes application code responsible for browser-owned dialog geometry.

### Keep visual backdrop ownership in CSS

The existing `.auth-dialog::backdrop` rule remains the sole dimming treatment. The change does not introduce a backdrop element, z-index management, or scripted visual state.

## Risks / Trade-offs

- [Backdrop light dismissal is unavailable in supported Safari versions] - Preserve the visible close action and Escape dismissal as complete alternatives.
- [A future browser may vary in close-request event details] - Assert the declarative attribute and user-visible closure in the existing real-browser component suite.
- [Changing overlay type could weaken credential isolation] - Retain `showModal()` and verify the element remains a native modal dialog.

## Migration Plan

1. Add `closedby="any"` and remove the backdrop click handler.
2. Update focused browser coverage for the declarative contract and native dismissal.
3. Run formatting, focused browser tests, lint, typecheck, and strict OpenSpec validation.

Rollback removes the attribute and restores the previous handler. No data, deployment, session, or iframe migration is required.

## Open Questions

None.
