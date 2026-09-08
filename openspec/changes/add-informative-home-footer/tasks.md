## 1. Content and Dependency Preparation

- [ ] 1.1 Review the prepared `pages/` briefs, confirm the public operator/support contact and factual About/Help copy, and resolve every affected publication input; keep editorial notes and unsupported legal/retention claims out of the product. The forwarding plan is owned by [ravecat/infra#2](https://github.com/ravecat/infra/issues/2); The user approved `support@d20.ravecat.io` and `rights@d20.ravecat.io` on 2026-09-07 and authorized implementation during provisioning; publication still waits for verified receipt/monitoring evidence. Planning does not authorize mail implementation.
- [ ] 1.2 Coordinate `/privacy`, `/terms`, and the FAQ deletion answer at `/help#delete-account` with #248, #247, and Meta metadata issue #249. Keep Privacy's direct link and the exact Meta instructions URL consistent; retain deletion behavior under #247 and public Help hosting under #268.
- [x] 1.3 Recheck current App layout and Home consumers against any subsequently integrated #264 changes; preserve catalog props, carousel behavior, and existing narrow/wide spacing.

## 2. Public Product Information

- [ ] 2.1 Add public `/about`, `/help`, and `/contact` routes and pages from the prepared briefs using existing Phoenix/frontend boundaries and the shared one-column article layout; verify direct anonymous access, titles, headings, contents links, and the shared footer.
- [ ] 2.2 Implement `/help#faq` and its expanded deletion answer at `/help#delete-account` in readable initial Help HTML, including the stable id and revision date. Verify direct fragment landing below the fixed header; add no separate deletion page or footer item.
- [x] 2.3 Implement `/contact` with the approved support/feedback and rights addresses, ordinary mailto links, concise inquiry guidance, and a link to `/rights-holders`; verify public access and that no form or public issue disclosure is required. Mailbox activation remains an external publication check.

- [x] 2.4 Implement the public `/rights-holders` page with the approved rights address, game proposal and rights-concern guidance, and a Contact / Support cross-link. Add route tests and Storybook coverage for both contact pages, including exact mailto targets and responsive rendering.

- [x] 2.5 Rewrite About as a warm fan-project invitation to players, publishers, developers, and designers. Replace the Games promotion and technical session copy with collaboration links to the existing Contact, rights-holder, and developer pages. Verify link targets and review light/dark screenshots at all three Storybook viewports.

## 3. Footer Presentation

- [x] 3.1 Use one shared footer composition in App Layout. Remove compact/informative selection from Footer, Layout, Home, and Storybook decorators; preserve existing narrow/wide shell geometry and verify the same grouped links on every consumer.
- [x] 3.2 Implement the full-width page surface, equal Explore/Help desktop columns, fine separators, current-year attribution, and Privacy/Terms legal strip from the revised layout design.
- [x] 3.3 Implement native mobile disclosures at 48rem and below, independent toggles, native expanded semantics, 44px summaries and hidden-link exclusion; match links in CSS-selected desktop lists.
- [x] 3.4 Verify CSS-only desktop/mobile transitions: desktop exposes every destination once; mobile open state survives width changes. Automatic focus transfer, focused-link exceptions and state resets are superseded by the native simplification in 3.13.
- [ ] 3.5 Preserve shell safe-area/inset geometry, theme contrast, visible focus, and 320px/200-percent reflow; keep Privacy/Terms visible and wrapping; disable optional disclosure transitions under reduced motion and avoid animated breakpoint geometry.
- [ ] 3.6 Verify the footer remains reachable on empty and short Home pages and does not overlap Workspace controls or change authentication, game details, or catalog behavior.
- [x] 3.7 Apply the review refinement: match Home's light/dark page background, tighten spacing, label the link About, remove the repeated brand/tagline introduction, and keep only Default and Mobile expanded stories under Widgets/Footer. Remove the duplicate footer-focused Home story; verify ordinary Home integration, browser link/disclosure tests, and affected visual comparisons.

- [x] 3.8 Keep copyright and Privacy/Terms in a baseline-aligned wrapping row at every width, with matching inherited typography; verify 446px, 320px, and content-pressure wrapping with focused screenshots.
- [x] 3.9 Replace runtime Games with exact text `For Publishers and Rightholders` linking to the implemented `/rights-holders` page; update navigation/route tests and affected screenshots. The user authorized this with the approved rights address while mailbox provisioning continues; no separate catalog is requested.

- [x] 3.10 Consolidate groups into `footer.svelte`, remove `footer_group.svelte`, share one breakpoint listener, and use CSS for heading/control visibility and the expansion indicator. Verify existing disclosure, focus, fallback, and visual tests, plus scoped formatting/lint and type checks.

- [x] 3.11 Replace the JavaScript mobile presentation class with viewport media queries, retain enhancement fallback and focus handling, and shorten the component class prefix to `footer`. Verify browser interactions, unchanged screenshots, formatting/lint, and type checks.

- [x] 3.12 Remove the duplicated JavaScript media query and API availability guard; observe the directory and read its native flex direction to preserve mode-transition state/focus, initializing synchronously before interaction. Verify initial closed state, independent toggles, same-mode resizes, breakpoint focus, CSS operation without matchMedia, unchanged screenshots, and existing checks.

- [x] 3.13 Replace custom disclosure state and observers with native mobile details and CSS-selected static desktop lists with matching links. Remove obsolete focus/state-reset tests and test native keyboard toggles, state retention, unique accessible destinations, no-script markup, visual comparisons and frontend checks. This supersedes the implementation mechanisms in 3.10-3.12.

- [x] 3.14 Write Explore and Help directly in the footer markup, removing the local snippet, group array, link loops, and clientNavigation field. Apply use:inertia directly to the same applicable anchors, using each anchor href. Preserve existing native behavior. Verify browser interactions, unchanged visual comparisons, scoped formatting/lint, and type checks.

- [x] 3.15 Remove the redundant Layout unit suite and its layout-export/link assertions. Keep shell presentation in existing Storybook screenshots, footer targets in footer browser tests, and scrolling/focus contracts in the existing layout browser suite. Run the affected browser suites, Home visual comparisons, scoped formatting/lint, and type checks.

## 4. Focused Validation

- [ ] 4.1 Add route tests beside `test/d20_web/controllers/page_controller_test.exs` for new public destinations, direct navigation, and existing route preservation; run `mix test test/d20_web/controllers/page_controller_test.exs` or the narrower owning controller test file if split.
- [ ] 4.2 Add focused footer/page tests for group names, hrefs, consistent shared footer content, FAQ/deletion anchors, anonymous/authenticated states, empty catalog, toggle semantics, and lack of footer-triggered requests; run the relevant files with `bun run test:unit -- <test-path>` from `assets/`.
- [ ] 4.3 Update existing public/authenticated Home stories and add prepared-page coverage and only the two meaningful footer stories; use the existing 1280x720, 1024x640, and 320x900 presets in light/dark, including short content and focused links, with `bun run test:visual -- <story-path>`.
- [ ] 4.4 Use `$devtools-validations` to inspect desktop/mobile/desktop and mobile/desktop/mobile sequences around 48rem, same-mode orientation changes, independently open groups, retained native open state, reduced motion, keyboard traversal, and the always-visible legal row. Include 320px reflow, 200-percent zoom, native no-script disclosures where footer markup is available, safe-area/Workspace interaction, and no added third-party traffic.
- [ ] 4.5 Add focused browser coverage for the transition matrix, including 767/768/769 CSS-pixel boundary checks at the default root font size, one accessible link per destination despite CSS-selected representations, hidden-link exclusion, and direct `/help#delete-account` navigation; run `bun run test:browser -- <test-path>` from `assets/`.
- [ ] 4.6 Format only touched files using repository tools; run `mix assets.format.check`, `mix assets.lint`, `mix typecheck`, and `mix assets.build`, then `just check` for the cross-stack change. Resolve failures attributable to this delivery.
- [ ] 4.7 Verify supplementary 390x844, 768x1024, 1440x900 and 844x390 cases, the narrow/wide shell geometry, long contact addresses, expanded FAQ/policy sections, and 200-percent zoom against `layout.md` and `pages/README.md`; record actual rendering evidence without treating static mockups as tests.

## 5. Production Documents and Handoff

- [ ] 5.1 Obtain #248's verified Privacy/Terms and #247's usable deletion process/instructions. Verify anonymous HTTPS GETs to `/privacy`, `/terms`, and `/help` on `https://d20.ravecat.io` return 200 with readable content and revision dates; verify Help contains the deletion answer/id and the full `/help#delete-account` URL lands on it without authentication or JavaScript.
- [ ] 5.2 Validate every footer destination after deployment, including FAQ deep linking and the private contact path; record dated evidence and actual deletion-path verification, including provider-only/no-email and lost-access guidance, from #247.
- [ ] 5.3 Supply `/privacy`, `/terms`, and `https://d20.ravecat.io/help#delete-account` with production evidence to #249 as Privacy Policy, Terms of Service and deletion instructions inputs. Keep dashboard mutation, review, business verification and publication under their existing issues; do not enter the Help document as a callback or claim Meta approval from footer delivery.

## 6. Reconciliation and Completion

- [ ] 6.1 Reconcile #268 acceptance, these tasks, linked document contracts, and verification notes with observed delivered behavior; retain incomplete #247/#248 or external Meta tasks in their owning issues.
- [ ] 6.2 Run `mix openspec.check` and `openspec validate --all --strict --no-interactive`; after every footer delivery task is complete, use `$openspec-archive-change`, synchronize the new capabilities, rerun strict validation, and confirm the change is absent from `openspec list --json`.
- [ ] 6.3 Include reconciled specifications and implementation/tests in the semantic delivery commit; record rollback that preserves published policy/deletion URLs and coordinate any provider disruption with #252 before closing #268.
