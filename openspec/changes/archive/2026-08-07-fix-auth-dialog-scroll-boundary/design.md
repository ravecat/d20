## Context

`AuthDialog` already uses a flex-column panel and an `.auth-panel__content` overflow container, but the description and auth notices are siblings above that container. On constrained viewports, the title, description, and notices all remain fixed while only the forms and provider section scroll. The result contradicts the intended single-body dialog structure and reduces the usable scrolling area.

The shared component must retain native `<dialog>` behavior, the existing safe-area-aware mobile inset, content-sized desktop layout, conditional Register and Login branches, and accessible DOM order.

## Goals / Non-Goals

**Goals:**

- Keep only the title row and close action outside the scroll region.
- Scroll every subsequent row as one body, beginning with the description and ending with the active mode's final content.
- Place the native body scrollbar at the dialog surface edge while retaining the same responsive inset for the title and body content.
- Preserve intrinsic desktop sizing and internal scrolling only when content exceeds the available block size.
- Prove that body scrolling does not move the title row.

**Non-Goals:**

- Changing dialog state, focus ownership, authentication forms, responsive outer geometry, or unrelated visual styling.
- Adding scripted measurement, scroll restoration, custom scrollbars, scrollbar-width calculations, or another nested scrolling region.

## Decisions

### Expand the existing content container

Move the description and conditional notices inside `.auth-panel__content`, ahead of the mode-specific branch. Keep the title row as its only preceding sibling. This preserves semantic DOM order and reuses the existing scroll boundary instead of adding another wrapper or scroll owner.

Alternative considered: make the complete `.auth-panel` scroll. Rejected because that would scroll the title and close action out of view.

### Make the body a shrinking flex column

Keep `min-block-size: 0`, `overflow-y: auto`, and `overscroll-behavior: contain` on the body, and make it a column with the existing inter-row gap. The panel remains the size-constrained flex parent, so desktop content keeps its intrinsic height while short viewports shrink only the body.

Alternative considered: calculate a body height from the title row and viewport. Rejected because flex sizing already expresses the constraint without DOM measurement or duplicated geometry.

### Move responsive inset onto the fixed and scrolling regions

Remove padding from the outer dialog surface. Give the title row its existing block-start and inline inset, and give the body scroller its existing inline and block-end inset. Use the existing local literals of `1.5rem` on wider viewports and `1rem` at the mobile breakpoint. This lets the body scrollport reach the surface's inline edges, where the user agent draws its native scrollbar, while padding inside the body keeps child content separated from that scrollbar.

Alternative considered: offset the existing nested scroll container with negative margins. Rejected because it couples the scroll boundary to compensating geometry and makes responsive changes harder to reason about.

Alternative considered: add a custom property for the shared inset. Rejected because the two responsive values are local to this component and their repeated use is clearer than introducing a token without wider semantic reuse.

## Risks / Trade-offs

- [Moving notices into the scroller changes their fixed position on short viewports] -> This is the requested behavior and keeps the entire body reachable in document order.
- [A flex child can refuse to shrink and escape its parent] -> Retain `min-block-size: 0` and verify real browser overflow dimensions.
- [Scrolling the body could move the title unexpectedly through an ancestor] -> Assert that the title position remains stable while the inner body scroll position changes.
- [Native scrollbar width and overlay behavior vary by browser and platform] -> Assert the scrollport edge and its internal padding instead of an exact scrollbar width.
