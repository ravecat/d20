## Context

On 2026-09-08, the prepared `http://localhost:5000/` page initially loaded assets from `.worktrees/informative-home-footer`, with `grid-template-rows: auto 1fr`. At approximately 697x807 CSS pixels, the footer box was 169px high and its inner content was 106px high. Master already uses `minmax(auto, 1fr) auto`. The existing browser page subsequently switched to master's assets during investigation.

During investigation, master advanced from `03b7735` to `5548458` (`style(shell): refine layout spacing and typography`), bringing the observed `auto 1fr` layout into the primary checkout. The correction preserves that commit's spacing and typography. Workspace renders the supplied header, main, and footer followed by a zero-height overlay host. The header is fixed. A vertical flex layout expresses main's growth without relying on sibling track positions.

## Goals / Non-Goals

**Goals:** Keep footer content at the bottom of short pages and after overflowing content, with natural disclosure height and existing document scrolling.

**Non-Goals:** Footer content redesign, publication, server configuration, package changes, or changes in the other worktree.

## Decisions

- Replace the outer Grid with a column Flexbox and assign `flex: 1` to `.layout__content`. Keep the existing `100dvh` minimum, border-box sizing, responsive header offset, and footer padding.
- Restoring Grid's original main-first flexible row would also work. Explicit growth on main makes the ownership clearer and avoids assigning flexibility by an implicit row position. No fixed footer or JavaScript measurement is needed.
- Use existing layout/footer browser tests and focused manual review through the selected development tab. This small CSS change does not require a new test harness or duplicate screenshot baselines.

## Risks / Trade-offs

- A short-page correction must not introduce nested scrolling or hide long content. Run the existing document-scroll/focus tests and inspect a short-height viewport.
- Development assets can originate from another checkout. Verify the Vite source path is the primary checkout before final review.
- Retain prepared route, authentication, carousel state, and disclosure state; restore temporary validation changes and viewport settings.

## Rollback

Revert the layout CSS change. No data or contract migration is involved.

## Open Questions

None.
