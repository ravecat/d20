## Context

Issue [#274](https://github.com/ravecat/d20/issues/274) owns this change in the separate `.worktrees/game-description-flow` worktree, created from clean baseline `d9335ba6`. The reported page at 1397x808 has a description panel with 520px client height, 571px scroll height, and `overflow-y: auto`.

`assets/js/pages/game/ui/game.svelte` caps `.game-detail-description-panel` with `max-block-size: clamp(18rem, calc(100dvb - 18rem), 38rem)` and enables internal scrolling, overscroll containment, and a stable scrollbar gutter. Its `48rem` media query already removes the cap and enables visible overflow for narrow screens. The existing app shell uses document scrolling.

The authoritative activation-layout and responsive-spacing specifications require wide-screen internal description scrolling. The separate active `refine-borderless-app-shell` change touches the responsive-spacing capability's page insets, not this description requirement; leave its artifacts and scope intact.

## Goals / Non-Goals

**Goals:** Size descriptions to their full content at every viewport width, scroll the document to read long descriptions, and retain compact short and empty states.

**Non-Goals:** Changes to shell behavior, grid placement, typography, metadata, launch forms, lobbies, routes, backend behavior, or iframe contracts.

## Decisions

- Delete the standalone description-panel rule that owns the height cap, `overflow-y`, `overscroll-behavior`, and `scrollbar-gutter`. Delete its now-redundant narrow-screen override. Default block sizing and the existing start-aligned grid provide natural height without new CSS values or JavaScript measurements.
- Preserve the shared panel styles, 40/60 split above `48rem`, stacked placement at and below `48rem`, gaps, text wrapping, accessible names, and DOM order. A taller description extends the document; the activation column remains at its natural height and scrolls with the page.
- Validate with the existing game unit suite, app layout browser suite in Chromium and Firefox, scoped formatting/lint, and frontend typecheck. This reversible CSS deletion does not need new automated tests or screenshot baselines.
- Through Chrome DevTools, verify the effective CSS on the reported page at desktop, tablet, and mobile widths. Confirm document scrolling from over the description reaches its final text and the footer, the panel has no internal scroll range, and short and empty descriptions remain naturally sized. Temporary browser-only content and style previews must be restored after inspection.

## Risks / Trade-offs

- A longer document moves activation controls out of view during reading. This follows the requested page-scrolling behavior; no sticky activation control is introduced.
- A browser tab can load assets from a different checkout. Check the source origin and effective styles during validation, then verify the actual integrated source after transfer to `master`.
- The responsive-spacing specification's Purpose still mentions bounded description overflow. Refresh that sentence when synchronizing this change into the authoritative specification.

## Delivery and Rollback

After implementation and prearchive validation, reconcile tasks, synchronize and archive this change, validate OpenSpec, and include the finalized artifacts with the CSS in one semantic completion commit. The parent session handles the authorized local linear transfer to `master`, integrated-source verification, issue completion, and worktree cleanup as delivery follow-through. No remote publication or runtime configuration change is required.

Rollback restores the removed description CSS. No data migration or contract rollback is needed.

## Open Questions

None.
