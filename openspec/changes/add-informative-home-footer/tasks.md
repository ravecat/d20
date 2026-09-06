## 1. Content and Dependency Preparation

- [ ] 1.1 Confirm the public operator/support contact and factual About/Help content before authoring publishable copy; record the responsible content owner without inventing legal or retention facts.
- [ ] 1.2 Coordinate `/privacy`, `/terms`, and the FAQ deletion answer at `/help#delete-account` with #248, #247, and Meta metadata issue #249. Keep Privacy's direct link and the exact Meta instructions URL consistent; retain deletion behavior under #247 and public Help hosting under #268.
- [ ] 1.3 Recheck current App layout and Home consumers against any subsequently integrated #264 changes; preserve catalog props, carousel behavior, and existing narrow/wide spacing.

## 2. Public Product Information

- [ ] 2.1 Add public `/about`, `/help`, and `/contact` routes and pages using the existing Phoenix and frontend boundaries; verify direct anonymous access, titles, and headings.
- [ ] 2.2 Implement `/help#faq` and its expanded deletion answer at `/help#delete-account` in readable initial Help HTML, including the stable id and revision date. Verify direct fragment landing below the fixed header; add no separate deletion page or footer item.
- [ ] 2.3 Publish the confirmed private contact path with a copyable address/mail link and concise bug/account/publisher inquiry guidance; verify that no form or public issue disclosure is required.

## 3. Footer Presentation

- [ ] 3.1 Extend App-owned Footer and Layout with an explicit informative/compact presentation independent of width; select informative only from Home and preserve compact For developers plus legal links elsewhere.
- [ ] 3.2 Implement the full-width neutral surface, centered introductory line, equal Explore/Help desktop columns, fine separators, current-year attribution, and Privacy/Terms legal strip from the revised Apple-reference design.
- [ ] 3.3 Implement mobile disclosure rows at 48rem and below, independent toggles, accurate ARIA state, 44px triggers, hidden-link semantics, and all-links-visible enhancement fallback using the same link nodes as desktop.
- [ ] 3.4 Implement and verify desktop/mobile transitions: desktop exposes all links and resets mobile state; re-entering mobile closes groups except the focused-link group; same-mode resizing preserves state; disappearing triggers transfer focus to their visible headings.
- [ ] 3.5 Preserve shell safe-area/inset geometry, theme contrast, visible focus, and 320px/200-percent reflow; keep Privacy/Terms visible and wrapping; disable optional disclosure transitions under reduced motion and avoid animated breakpoint geometry.
- [ ] 3.6 Verify the footer remains reachable on empty and short Home pages and does not overlap Workspace controls or change authentication, game details, or catalog behavior.

## 4. Focused Validation

- [ ] 4.1 Add route tests beside `test/d20_web/controllers/page_controller_test.exs` for new public destinations, direct navigation, and existing route preservation; run `mix test test/d20_web/controllers/page_controller_test.exs` or the narrower owning controller test file if split.
- [ ] 4.2 Add focused footer/page tests for group names, hrefs, compact/informative selection, FAQ/deletion anchors, anonymous/authenticated states, empty catalog, toggle semantics, and lack of footer-triggered requests; run the relevant files with `bun run test:unit -- <test-path>` from `assets/`.
- [ ] 4.3 Update the existing public/authenticated Home stories and add product-information coverage as needed; review desktop/tablet/mobile, light/dark, short-content, and focused-link states with the existing `bun run test:visual -- <story-path>` script.
- [ ] 4.4 Use `$devtools-validations` to inspect desktop/mobile/desktop and mobile/desktop/mobile sequences around 48rem, same-mode orientation changes, independently open groups, focus exceptions, reduced motion, keyboard traversal, and the always-visible legal row. Include 320px reflow, 200-percent zoom, no-script disclosure fallback where footer markup is available, safe-area/Workspace interaction, and no added third-party traffic.
- [ ] 4.5 Add focused browser coverage for the transition matrix, including 767/768/769 CSS-pixel boundary checks at the default root font size, one accessible link per destination, hidden-link exclusion, and direct `/help#delete-account` navigation; run `bun run test:browser -- <test-path>` from `assets/`.
- [ ] 4.6 Format only touched files using repository tools; run `mix assets.format.check`, `mix assets.lint`, `mix typecheck`, and `mix assets.build`, then `just check` for the cross-stack change. Resolve failures attributable to this delivery.

## 5. Production Documents and Handoff

- [ ] 5.1 Obtain #248's verified Privacy/Terms and #247's usable deletion process/instructions. Verify anonymous HTTPS GETs to `/privacy`, `/terms`, and `/help` on `https://d20.ravecat.io` return 200 with readable content and revision dates; verify Help contains the deletion answer/id and the full `/help#delete-account` URL lands on it without authentication or JavaScript.
- [ ] 5.2 Validate every footer destination after deployment, including FAQ deep linking and the private contact path; record dated evidence and actual deletion-path verification, including provider-only/no-email and lost-access guidance, from #247.
- [ ] 5.3 Supply `/privacy`, `/terms`, and `https://d20.ravecat.io/help#delete-account` with production evidence to #249 as Privacy Policy, Terms of Service and deletion instructions inputs. Keep dashboard mutation, review, business verification and publication under their existing issues; do not enter the Help document as a callback or claim Meta approval from footer delivery.

## 6. Reconciliation and Completion

- [ ] 6.1 Reconcile #268 acceptance, these tasks, linked document contracts, and verification notes with observed delivered behavior; retain incomplete #247/#248 or external Meta tasks in their owning issues.
- [ ] 6.2 Run `mix openspec.check` and `openspec validate --all --strict --no-interactive`; after every footer delivery task is complete, use `$openspec-archive-change`, synchronize the new capabilities, rerun strict validation, and confirm the change is absent from `openspec list --json`.
- [ ] 6.3 Include reconciled specifications and implementation/tests in the semantic delivery commit; record rollback that preserves published policy/deletion URLs and coordinate any provider disruption with #252 before closing #268.
