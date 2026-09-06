## Why

D20's footer currently exposes only a developer link, leaving visitors without a clear route to product information, help, or policies. An informative home footer should make these destinations discoverable and connect the public legal and deletion pages already required by the Facebook Login publication work.

## What Changes

- Add an informative home footer with a short introductory line, a centered column directory, and a distinct legal strip. Use apple.com as the layout and responsive-interaction reference; retain the useful D20 destinations identified through Board Game Arena.
- Define public About, How to play/FAQ, and Contact/Support pages at `/about`, `/help`, and `/contact`; reuse `/games` and `/developers`.
- Keep Privacy and Terms in the legal strip. Put account/data deletion inside FAQ at `/help#delete-account`, linked directly from Privacy and supplied to Meta as the instructions URL; no separate deletion page or footer item is needed. Content and deletion behavior remain owned by #248 and #247.
- Keep the expanded composition on Home. Retain compact developer and legal navigation on other pages using the existing App layout.
- Specify desktop columns and mobile disclosure rows at the existing 48rem breakpoint, including resize/orientation behavior, keyboard focus, hidden-link semantics, no-script fallback, and reduced motion.
- Specify desktop/mobile ASCII wireframes, truthful content, ownership, production URL verification, and the Meta publication handoff.
- Provide a concrete layout reference covering informative/compact, narrow/wide, light/dark, existing Storybook presets, supplementary viewport boundaries, and resize/focus states.
- Prepare individual About, Help/FAQ, Contact, Privacy, and Terms page briefs with block order, copy or content contracts, public anchors, and explicit publication inputs.
- Require all mandatory destinations to work before accepting footer delivery. Do not substitute placeholders or hide an incomplete mandatory policy link to pass acceptance.

## Capabilities

### New Capabilities

- `informative-home-footer`: Home footer composition, compact shared navigation, link contracts, accessibility, and integration acceptance.
- `public-product-information`: About, help, and contact content, plus the public-document interface required from the existing legal/deletion work.

### Modified Capabilities

None. Existing App ownership, shell spacing, game discovery, and authentication contracts remain in force. This change adds requirements without rewriting those capabilities.

## Impact

- Tracking: [#268](https://github.com/ravecat/d20/issues/268). This turn prepares specifications only; all implementation and release tasks remain unchecked.
- Existing owners: [#247](https://github.com/ravecat/d20/issues/247) owns deletion and its instructions; [#248](https://github.com/ravecat/d20/issues/248) owns Privacy/Terms. [#249](https://github.com/ravecat/d20/issues/249), [#251](https://github.com/ravecat/d20/issues/251), and [#252](https://github.com/ravecat/d20/issues/252) own Meta settings, review, and publication. Their acceptance criteria are preserved.
- Expected frontend scope: `assets/js/app/ui/footer.svelte`, `assets/js/app/layout.svelte`, Home's layout selection, new product-information pages, and focused tests and stories.
- Expected backend scope: public product-information routes in `lib/d20_web/router.ex`, page controller/rendering, and route tests. Legal/deletion endpoints are coordinated with their existing owners.
- No new package, database migration, channel/AsyncAPI change, game engine change, OAuth change, or iframe contract change is required by this footer specification.
- The carousel in #264 has an independent acceptance boundary. This specification uses the committed `master` baseline and requires none of that worktree's uncommitted changes.
- Rollback can restore the previous footer composition while retaining working policy/deletion URLs required by a published Meta app.

## Artifact Guide

- [Design](design.md): decisions, ownership, responsive state transitions, and Meta handoff.
- [Layout and viewport reference](layout.md): geometry, variants, viewport matrix, wireframes, and review states.
- [Prepared page briefs](pages/README.md): page index, shared article layout, individual drafts, and missing publication inputs.
- [Footer capability](specs/informative-home-footer/spec.md) and [public-information capability](specs/public-product-information/spec.md): normative acceptance scenarios.
- [Implementation tasks](tasks.md): work remains pending until separately implemented and verified.
