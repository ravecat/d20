## Context

`Header` conditionally mounts `AuthDialog` and currently binds the unauthenticated Register button to a reactive `HTMLButtonElement` reference. The header passes that element into `AuthDialog`, whose close handler sets the bound `open` state to false and calls `.focus()` on the supplied element.

The element reference has no other purpose. It also gives server-prompted Login mode the Register button as a return target even though that button did not invoke the prompt. The native modal already owns focus entry and modal focus behavior, while the caller only needs the bound open state to remove the dialog after close.

## Goals / Non-Goals

**Goals:**

- Remove the caller-owned DOM reference and return-focus prop.
- Keep native modal opening, focus entry, dismissal, and conditional unmounting unchanged.
- Keep the header Register action and all account flows unchanged.

**Non-Goals:**

- Remove focus movement into the opened dialog or between Register and Login modes.
- Add a replacement focus manager, custom Tab trap, trigger abstraction, or browser polyfill.
- Change dialog layout, forms, routes, server prompts, or authentication behavior.

## Decisions

### Leave post-close focus placement to the native dialog

The close handler will only synchronize `open = false`. `AuthDialog` will not accept a caller-supplied element or explicitly focus caller-owned DOM after close. This removes the complete coupling instead of retaining an optional prop with no consumers.

Keeping `returnFocusTo` available for possible future use was rejected because it would preserve a public component contract and dead branch without a current workflow. Replacing it with a selector or callback was rejected because both keep application-managed focus restoration without a current requirement.

### Retain focus assertions only for behavior the application still owns

The browser test will continue to verify that opening and mode switching place focus in the active account form. Assertions that closing forces focus to Register will be removed because the application will no longer implement that guarantee. Dialog closure and clean-state reopening remain covered independently.

## Risks / Trade-offs

- [A browser may place focus differently after close] -> Accept native post-close behavior until a concrete workflow requires an explicit destination.
- [Removing the close assertion could hide a future native focus regression] -> Keep user-visible close and reopen coverage and restore a focused contract only with a defined accessibility requirement.
- [Shared Login and Register behavior could diverge accidentally] -> Remove the prop from the shared dialog itself and validate both modes through the existing header browser suite.

## Migration Plan

1. Remove the Register-button state, binding, and dialog prop at the header boundary.
2. Remove the prop declaration, destructuring, and explicit focus call from `AuthDialog`.
3. Remove only the browser assertions and wording that require forced focus restoration.
4. Run focused browser tests, frontend lint, typecheck, and strict OpenSpec validation.

Rollback restores the removed prop, binding, focus call, and assertions. No data, deployment, session, or iframe migration is required.

## Open Questions

None.
