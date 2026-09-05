## Why

D20's footer currently exposes only a developer link, leaving visitors without a clear route to product information, help, or policies. An informative home footer should make these destinations discoverable and connect the public legal and deletion pages already required by the Facebook Login publication work.

## What Changes

- Add an informative home footer with a short D20 description, grouped product/help navigation, and a distinct legal strip, informed by Board Game Arena's information architecture.
- Define public About, How to play/FAQ, and Contact/Support pages at `/about`, `/help`, and `/contact`; reuse `/games` and `/developers`.
- Require direct links to `/privacy`, `/terms`, and `/data-deletion`, with content and deletion behavior delivered by existing issues #248 and #247.
- Keep the expanded composition on Home. Retain compact developer and legal navigation on other pages using the existing App layout.
- Specify desktop/mobile ASCII wireframes, accessibility, responsive behavior, truthful content, ownership, production URL verification, and the Meta publication handoff.
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
