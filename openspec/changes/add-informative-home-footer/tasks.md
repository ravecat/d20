## 1. Content and Dependency Preparation

- [ ] 1.1 Confirm the public operator/support contact and factual About/Help content before authoring publishable copy; record the responsible content owner without inventing legal or retention facts.
- [ ] 1.2 Coordinate the `/privacy`, `/terms`, and `/data-deletion` link contracts with #248 and #247. Ensure their owning artifacts describe readable initial HTML, anonymous access, and accurate instructions before dependent implementation; retain deletion behavior under #247.
- [ ] 1.3 Recheck current App layout and Home consumers against any subsequently integrated #264 changes; preserve catalog props, carousel behavior, and existing narrow/wide spacing.

## 2. Public Product Information

- [ ] 2.1 Add public `/about`, `/help`, and `/contact` routes and pages using the existing Phoenix and frontend boundaries; verify direct anonymous access, titles, and headings.
- [ ] 2.2 Implement the stable `/help#faq` section and practical discovery, play, account, browser, failure/recovery, support, and deletion guidance using actual delivered workflows.
- [ ] 2.3 Publish the confirmed private contact path with a copyable address/mail link and concise bug/account/publisher inquiry guidance; verify that no form or public issue disclosure is required.

## 3. Footer Presentation

- [ ] 3.1 Extend App-owned Footer and Layout with an explicit informative/compact presentation independent of width; select informative only from Home and preserve compact For developers plus legal links elsewhere.
- [ ] 3.2 Implement the description, Explore and Help groups, current-year attribution, and three-link legal strip with exact destinations from the design.
- [ ] 3.3 Implement wrapping desktop/tablet/mobile layout, existing safe-area/inset geometry, readable themed contrast, accessible targets, visible focus, and 320px/200-percent reflow without new animation or scripts.
- [ ] 3.4 Verify the footer remains reachable on empty and short Home pages and does not overlap Workspace controls or change authentication, game details, or catalog behavior.

## 4. Focused Validation

- [ ] 4.1 Add route tests beside `test/d20_web/controllers/page_controller_test.exs` for new public destinations, direct navigation, and existing route preservation; run `mix test test/d20_web/controllers/page_controller_test.exs` or the narrower owning controller test file if split.
- [ ] 4.2 Add focused footer/page tests for group names, hrefs, compact/informative selection, FAQ anchor, anonymous/authenticated states, empty catalog, and lack of footer-triggered requests; run the relevant files with `bun run test:unit -- <test-path>` from `assets/`.
- [ ] 4.3 Update the existing public/authenticated Home stories and add product-information coverage as needed; review desktop/tablet/mobile, light/dark, short-content, and focused-link states with the existing `bun run test:visual -- <story-path>` script.
- [ ] 4.4 Use `$devtools-validations` to inspect real-browser keyboard order, landmarks, visible focus, contrast, 320px reflow, 200-percent zoom, safe-area/Workspace interaction, internal navigation, and no added third-party traffic.
- [ ] 4.5 Format only touched files using repository tools; run `mix assets.format.check`, `mix assets.lint`, `mix typecheck`, and `mix assets.build`, then `just check` for the cross-stack change. Resolve failures attributable to this delivery.

## 5. Production Documents and Handoff

- [ ] 5.1 Obtain #248's verified Privacy/Terms and #247's usable deletion process/instructions. Verify anonymous HTTPS GETs to all three `https://d20.ravecat.io` document URLs return 200 with readable document text, title, revision date and no authentication or JavaScript dependency.
- [ ] 5.2 Validate every footer destination after deployment, including FAQ deep linking and the private contact path; record dated evidence and actual deletion-path verification, including provider-only/no-email and lost-access guidance, from #247.
- [ ] 5.3 Supply the three exact document URLs and evidence to #249 as Privacy Policy, Terms of Service and deletion instructions inputs. Keep dashboard mutation, review, business verification and publication under their existing issues; do not enter the document as a callback or claim Meta approval from footer delivery.

## 6. Reconciliation and Completion

- [ ] 6.1 Reconcile #268 acceptance, these tasks, linked document contracts, and verification notes with observed delivered behavior; retain incomplete #247/#248 or external Meta tasks in their owning issues.
- [ ] 6.2 Run `mix openspec.check` and `openspec validate --all --strict --no-interactive`; after every footer delivery task is complete, use `$openspec-archive-change`, synchronize the new capabilities, rerun strict validation, and confirm the change is absent from `openspec list --json`.
- [ ] 6.3 Include reconciled specifications and implementation/tests in the semantic delivery commit; record rollback that preserves published policy/deletion URLs and coordinate any provider disruption with #252 before closing #268.
