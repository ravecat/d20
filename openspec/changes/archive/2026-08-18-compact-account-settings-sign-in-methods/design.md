## Context

`AccountSettingsPage` currently renders fixed Google, Apple, and Discord rows from independent `{available, linked}` props. Every row includes a second status line, and unavailable unlinked providers remain visible with disabled controls. The authentication dialog already omits unavailable providers and owns trusted build-time SVG assets for the three provider identities.

The page is constrained to a single 46 rem column, so its independent username, email, and password cards leave substantial horizontal space unused on wide monitors. Its existing single-column flow and semantic sections must remain intact on narrow screens.

## Goals / Non-Goals

**Goals:**

- Apply one provider visibility rule in Account Settings: render only providers whose `available` prop is true.
- Show provider identity with the existing trusted SVG asset and visible provider name.
- Use one trailing state per provider: `Linked` text or a `Link` anchor.
- Let the page fill its shell and let the provider collection expand into responsive grids without changing document order or form behavior.
- Bound provider items between 13 rem and 20 rem when the container permits, letting items share remaining row space within those bounds before wrapping subsequent providers.
- Keep provider items on separate rows through the existing 34 rem mobile breakpoint before enabling the multi-item wrapping behavior on wider layouts.
- Keep every wrapped row on the same equal-width column tracks so a partial final row aligns with the row above.
- Split provider identity and state into separate adjacent blocks, make only the distinct `Link` control appear clickable, and replace it with a same-size muted non-interactive `Linked` control after linking.
- Stretch independent account cards that share a grid row to the same block size without fixed heights.
- Keep established-username supporting copy limited to its player-facing identification purpose and leave current claim-operation behavior unchanged.
- Keep the page inspectable through deterministic Storybook args and cover rendering branches in focused component tests.

**Non-Goals:**

- Change Inertia props, provider routes, sudo authorization, callback behavior, identity persistence, or server configuration.
- Add unlinking, retry, reauthentication, or provider health details.
- Extract a new generic provider component or redesign unrelated account fields.

## Decisions

### Derive one local available-provider collection

Build a typed Svelte derived collection from the existing Google, Apple, and Discord props and filter it by `available`. Render the collection with one keyed `each` block and omit the complete Sign-in methods section when the collection is empty.

This keeps Storybook controls reactive, removes three divergent markup branches, and makes the empty state explicit. Repeating three conditional blocks was rejected because it preserves duplication and makes later provider additions easier to render inconsistently.

### Reuse provider SVG assets without introducing a shared abstraction

Import the same trusted raw SVG files used by the authentication dialog and render each decorative icon with `aria-hidden="true"`. Keep the visible provider name as the accessible identity and give each compact `Link` anchor a provider-specific accessible name while preserving normal full-document navigation.

Extracting a shared component was rejected because the dialog and settings surface have different copy and interaction structure; sharing the stable assets avoids a premature UI abstraction.

### Use a responsive wrapping layout with semantic list markup

Render available methods as an unordered list whose items use a compact identity-and-state layout. The provider list uses an auto-fitting CSS Grid sized with `fit-content`. Each item contributes a 20 rem preferred inline size while grid tracks may shrink to 13 rem before another item wraps. Because every row shares the same grid tracks, a partial final row keeps the same width and inline alignment as the preceding row instead of growing independently. Through the existing 34 rem mobile breakpoint, the grid uses one track capped at 20 rem so every provider starts a separate row. On containers narrower than 13 rem, the track contracts to the available width instead of overflowing. Wider breakpoints continue to allow the independent username, email, and password cards to share two and then three page columns. The page header and provider card span the available columns, preserving document order and section semantics.

The page uses the full inline size supplied by the application shell instead of imposing its own maximum width. Account cards retain the grid default stretch behavior, so cards sharing a responsive row have equal block sizes while separate mobile rows remain content-driven.

This uses CSS only, so no viewport state, DOM measurement, or duplicated mobile markup is required. A wrapping flex layout was rejected because each flex line distributes free space independently, making a lone item in the final row wider than the columns above it. Keeping a fixed single column was rejected because it does not meet the wide-screen density goal.

### Separate provider identity from its state control

Each provider item uses a two-column grid with one flexible neutral identity block and one bounded state-control block. The identity block contains only the decorative icon and visible provider name and has no interactive semantics. Before linking, the state control is a normal full-document anchor with a distinct button surface. After linking, that anchor is replaced by a muted non-interactive `Linked` span with the same geometry. The outer list item only arranges the blocks and has no surface or pointer affordance, so it cannot be mistaken for the click target.

Define one page-local compact block size for provider identity blocks, provider state controls, text inputs, and form submit buttons. Reusing one local value was selected over changing global form tokens because the requested density change is limited to Account Settings.

### Avoid encoding current username immutability in supporting copy

When a username is already assigned, describe only that it identifies the player to others. Do not state that it cannot be changed. The server still rejects replacement through the existing claim operation; this change keeps presentation copy from making a permanent product promise while leaving identity behavior and authorization unchanged.

### Test behavior semantically and inspect layout in a real browser

Component tests assert visible provider names, provider-specific link names, linked text, and omission of unavailable or empty provider surfaces. Responsive layout is verified in the running Storybook at named desktop and mobile viewport sizes instead of coupling tests to CSS classes or geometry.

## Risks / Trade-offs

- [A linked provider becomes temporarily unavailable] -> Omit it consistently with the requested availability rule; durable identity data and server behavior remain unchanged and the provider returns when configuration is restored.
- [Multiple `Linked` labels are visually similar] -> Keep each label inside the provider item beside its icon and name so the association remains clear without repeating a secondary status sentence.
- [Three account cards become narrow at intermediate widths] -> Introduce columns only at supported breakpoints and keep every grid track at `minmax(0, 1fr)` so form controls can shrink without overflow.
- [Equal-height cards create unused space in shorter cards] -> Apply stretching only to cards that naturally share a grid row; mobile cards remain separate content-driven rows.
- [A fixed trailing slot could constrain localization] -> Size the slot for the current short English states and keep the provider identity track shrinkable without clipping or horizontal overflow.
- [A partial final provider row leaves unused inline space] -> Keep it left-aligned on the same shared grid tracks as the preceding row so column edges remain stable.
- [Removing immutability copy could imply an edit action exists] -> Keep the assigned username visible without rendering a replacement form or edit control.
- [Raw SVG rendering bypasses Svelte escaping] -> Use only repository-owned build-time assets, matching the existing authentication-dialog trust boundary.

## Migration Plan

Deploy as a frontend-only presentation change with existing page props and routes. Rollback restores the prior Svelte markup and scoped CSS; no data, configuration, session, or migration rollback is required.

## Open Questions

None.
