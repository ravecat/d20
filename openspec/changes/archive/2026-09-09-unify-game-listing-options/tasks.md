Sections 1-11 and their verification notes are historical records of earlier implemented steps in this same uncommitted #272 outcome. Section 12 records the implemented internal provider detail navigation; section 13 is the current raw-string continuation; its remaining tasks are checked only after implementation and verification. Current proposal/design/deltas supersede historical external BGG links and nullable route slugs. Prior test results do not validate the planned routing behavior. At planning start, the user index already contains lib/d20/games.ex, lib/d20/games/metadata.ex, lib/d20/games/sources/board_game_geek.ex, and lib/d20_web/controllers/page_controller.ex; preserve it and all other uncommitted work without staging or committing.

## 1. Unify scoped listing options

- [x] 1.1 Give playable and browsable optional `where`, `order_by`, and `limit` options with identical inline public typespecs and shared defaults.
- [x] 1.2 Reuse one private query-and-options execution path, preserving metadata behavior and intersecting caller filters with mandatory scope predicates.
- [x] 1.3 Update home and all live callers to use common options, preserving home limit, order, and non-overlap without positional compatibility APIs.

## 2. Verify behavior

- [x] 2.1 Extend existing catalog tests for scoped defaults, limit normalization, metadata bounds, keyword/dynamic intersection, caller ordering, mandatory-predicate protection, and empty selections.
- [x] 2.2 Run `mix test test/d20/games_test.exs test/d20_web/controllers/page_controller_test.exs`, touched-file formatting/checks, and focused strict Credo.
- [x] 2.3 Review the diff and validate `openspec validate unify-game-listing-options --strict --no-interactive`.

## 3. Use BGG identity with optional local fields

- [x] 3.1 Use mandatory positive BGG identity as catalog-envelope `id`, retain runtime metadata, and declare nullable local stage/slug without adding a struct, nested local record, metadata identity field, or availability flag.
- [x] 3.2 Update home serialization to numeric BGG `id` and existing `game` metadata, and preserve current local collection selection by excluding selected playable BGG IDs.
- [x] 3.3 Update frontend catalog types, identity keys, labels, fixtures, and tests; support local slug links and ordinary BGG navigation when slug is null, with neutral absent-stage presentation.

## 4. Verify and reconcile the continued change

- [x] 4.1 Verify catalog identity and metadata fallback with `mix test test/d20/games_test.exs test/d20_web/controllers/page_controller_test.exs`; preserve genuine local session/detail IDs and existing selection/order behavior.
- [x] 4.2 Run focused home unit/browser tests through the native Bun scripts, touched frontend format/lint checks, and type checking; verify external/local links, nullable-stage behavior, fallback cards, and unique accessible links.
- [x] 4.3 Validate the existing development page with the repository's DevTools workflow when available, run `just check` for this cross-stack contract change, and record any pre-existing or environmental failures accurately.
- [x] 4.4 Review the diff, reconcile the owning issue and OpenSpec artifacts with verified behavior, and confirm `git diff --check`, unchanged HEAD, and an empty index.

Historical lifecycle instruction for the completed steps above: after implementation verification, synchronize/archive and validate. For the current Section 12 planning turn, keep the change active, leave authoritative specs and the user-managed index untouched, and do not implement or commit. After separately authorized implementation, follow task 12.9. Keep #272 Open/In Progress.

## Prior verification before the map continuation

- Baseline catalog/controller suite passed 79 tests. The new scoped-default test failed against the old implementation because `list_playable/0` and `list_browsable/0` did not exist.
- Final `mix test test/d20/games_test.exs test/d20_web/controllers/page_controller_test.exs` passed 83 tests. Four additional tests cover default optional calls, native keyword/dynamic filter intersections, caller ordering, mandatory-predicate protection, empty selections, common normalized limits, and bounded metadata enrichment. Existing controller behavior remains covered.
- Touched-file `MIX_ENV=test mix format` and `--check-formatted` passed for the context, controller, and catalog test. `MIX_ENV=test mix credo --strict lib/d20/games.ex lib/d20_web/controllers/page_controller.ex test/d20/games_test.exs` checked exactly three files and passed.
- Diff review and `git diff --check` passed. The index is empty and HEAD remains `7535b35`; no staging or commit is authorized for this change.
- `openspec validate unify-game-listing-options --strict --no-interactive` passed.
- The first pass was archived after synchronizing catalog and home-discovery specifications; all 82 OpenSpec items and nine active-change checks passed. The same uncommitted artifact set was reactivated for the approved map continuation. Those prior results do not verify the new contract. The owning issue remains Open/In Progress.

## Map continuation verification

- The focused catalog/controller suite passed all 83 tests with exact four-field envelope checks, BGG identity during metadata fallback, preserved collection membership, and local-ID ordering. Touched four-file Elixir formatting and strict Credo passed.
- Home unit tests passed 8 tests. Home browser tests passed 7 tests across Chromium and Firefox, with one existing Firefox reduced-motion skip. Existing screenshot baselines were unchanged. Browser tests verify the repository's mocked Inertia attachment boundary and that external clicks are not prevented by the component; they do not exercise a live production Inertia visit.
- Full frontend type checking passed with no errors or warnings. Full frontend formatting and lint checks passed. Locked frontend dependencies were installed in the worktree without changing the lockfile.
- Read-only review found no product defects. The catalog map, serializers, BGG identity, nullable links/stages, metadata fallback, and Inertia attachment cleanup are consistent with the four-field contract.
- `MIX_ENV=test just check` was run with the already installed Nix-store `just` binary because `just` was absent from the session PATH. Compilation and backend formatting passed; the full backend suite ran 833 tests with one failure in unchanged `test/d20/games/game_test.exs:62`, and full Credo reported three existing nesting findings in unchanged Koala game code. The failing schema test also fails alone: updating every row to the removed `planned` stage can violate both the stage-domain and engine-required constraints, while the test expects only the former constraint name. The catalog listing is not involved; this continuation changes neither that test, the schema, nor the migrations. The composite check is not green, and its later steps are not claimed to have run.
- DevTools selected the existing `http://localhost:5000/` page and observed no console warnings/errors before changes. Its listening Phoenix process runs from the main checkout, not this worktree, so that page does not validate the changed implementation. No unrelated tab, user server, or browser state was modified.
- Additional full frontend tests ran 57 files: 53 passed and four failed, with 281 tests passed, three failed, and one skipped. The failures are the unchanged page-layout suite's missing jsdom `window.matchMedia` and eight-pixel differences in the unchanged Maximum Only player-count story at desktop, tablet, and mobile. The page-layout import failure reproduces in isolation before any tests run. No affected home test or home screenshot failed, and no screenshot baseline was updated. The full frontend suite is not green.
- `bun run storybook:build` passed with the existing chunk-size warning. Build output is ignored; no generated artifact or dependency change is included in the diff.
- Native `openspec archive unify-game-listing-options --yes` synchronized all four affected capabilities and returned this same change to `archive/2026-09-08-unify-game-listing-options/`. Strict validation passed all 82 items; `MIX_ENV=test mix openspec.check` passed for nine active changes, and this change is absent from `openspec list --json`. The archive tool's extra EOF blank lines were removed from the four synchronized specs. Final diff checks pass, the index is empty, and HEAD remains `7535b35`. Issue #272 remains Open/In Progress; all code and artifacts are deliberately unstaged and uncommitted for user review.

## 5. Keep the catalog identity field named id

- [x] 5.1 Return `id: game.bgg_id`, serialize numeric `id`, and update catalog types, consumers, fixtures, and assertions; leave persisted/provider `bgg_id` and local/session TypeIDs unchanged.
- [x] 5.2 Run focused backend and home unit/browser tests, touched formatting/lint, and frontend type checking. This narrow naming correction does not repeat the previously recorded broad-suite failures.
- [x] 5.3 Reconcile the owning issue and specs for native synchronization/archive; verify the ready change, unchanged HEAD, and an empty index. Run the post-archive validation described above after archival.

## Catalog id naming verification

- Catalog maps now expose `id: pos_integer()` assigned from `Game.bgg_id`, and the frontend receives `id: number`. Controller exclusion still queries `game.bgg_id`; metadata provider fields, local schema IDs, session/detail IDs, and SQL ordering are unchanged. The type documentation distinguishes the two identities.
- `mix test test/d20/games_test.exs test/d20_web/controllers/page_controller_test.exs` passed all 83 tests. Focused home unit/browser tests passed 15 tests with one existing skip. Frontend type checking, touched ESLint/Oxfmt, touched Elixir formatting, and focused strict Credo passed. No screenshot baseline changed.
- This is a narrow field-name correction within the same uncommitted outcome. The broad-suite and live-browser limitations recorded above remain applicable; those unrelated failures were not rerun. Diff review confirms the catalog ID contains the BGG value and no old response alias remains.
- Native archival synchronized all four affected capabilities for the final `id` contract. Post-archive strict validation passed all 82 items, the lifecycle check passed for nine active changes, and this change is absent from the active list. The index is empty, HEAD remains `7535b35`, and diff checks pass.

## 6. Implement provider Hot and detail fetching

- [x] 6.1 Replace the two old provider detail APIs with fetch_games accepting a positive ID or a list, validating and deduplicating input, returning ordered requested attrs, and preserving empty/error behavior. Update all local enrichment callers without aliases.
- [x] 6.2 Split detail requests into batches of at most 20 with at most two concurrent batches, existing authenticated HTTP options, a 15-second task timeout, no leaked tasks, and all-or-error aggregation.
- [x] 6.3 Add fetch_hot_games with limit normalization, one Hot request, root/ID validation, unique random selection, delegated detail fetching, selected-ID fallback, and credential-safe warning behavior.
- [x] 6.4 Extend provider tests for singleton/list input, invalid/duplicate IDs, empty/zero shortcuts, request size and concurrent bound, completion ordering, task/transport/HTTP/parse failures, Hot limits/root/IDs, missing details, and detail-batch fallback. Synchronize concurrency tests with messages or monitors, not Process.sleep.

## 7. Compose provider discovery with optional local association

- [x] 7.1 Replace list_browsable with limit-only list_by_provider, merge only visible-stage local matches by BGG identity without selecting or changing provider membership, and preserve the four-field map and per-entry Metadata fallback without database writes.
- [x] 7.2 Update home to call provider listing directly without playable exclusion, preserve playable options, remove unused imports, and log/render empty Games on discovery error while preserving Playable.
- [x] 7.3 Update catalog/controller tests for empty persistence, default and normalized limits, provider-only and visible/hidden/disabled/engine-less matches, empty visibility, overlap, selected order, metadata degradation, and Hot discovery failure; retain local list/playable behavior coverage.
- [x] 7.4 Add focused frontend overlap coverage proving the same BGG game has one canonical accessible link in each owning section, unique section-specific label IDs, and no accessible decorative duplicates; preserve local/external links and existing visuals.

## 8. Verify and reconcile provider discovery

- [x] 8.1 Run mix test for test/d20/games/sources/board_game_geek_test.exs, test/d20/games_test.exs, and test/d20_web/controllers/page_controller_test.exs; run touched Elixir formatting and strict Credo.
- [x] 8.2 Run focused home unit/browser tests through native Bun scripts, touched frontend format/lint checks, and frontend type checking. Use the DevTools workflow for any changed live UI validation and state when the available page does not run this worktree.
- [x] 8.3 Run the native cross-stack just check and record actual outcomes, distinguishing pre-existing failures already documented above from regressions; do not repair unrelated code or baselines.
- [x] 8.4 Review the final diff, update verification evidence and the owning issue, and reconcile the five capability deltas for native synchronization/archive. Run the required post-archive checks described above after archival.
- [x] 8.5 Confirm git diff --check, unchanged HEAD 7535b35, and an empty index; leave all changes unstaged and uncommitted without closing issue #272 or marking delivery Done.

## Hot provider continuation verification

- Home overlap regression verifies one accessible local link in each independently delivered section, distinct labels, and unique DOM IDs. `bun run test:unit -- tests/pages/home/ui/home.test.ts` passed 9 tests. `bun run test:browser -- tests/pages/home/ui/home.browser.test.ts` passed 7 tests with the existing Firefox reduced-motion skip. No visual baseline changed.
- Touched home test Oxfmt and ESLint checks passed. `bun run typecheck` passed with zero errors and warnings. The previously identified live DevTools page still belongs to the main checkout; no live-worktree validation is claimed for this backend continuation.
- Final `mix test test/d20/games/sources/board_game_geek_test.exs test/d20/games_test.exs test/d20_web/controllers/page_controller_test.exs` passed 114 tests (seed 461728). Provider tests cover singleton/list input, strict positive response IDs including malformed numeric prefixes, batching, maximum concurrency, ordering, early cancellation, and actual 15-second task timeout cleanup. Context/controller coverage verifies provider membership with no local rows or visible stages, optional local links, overlap, normalized limits, and distinct Hot-discovery/detail-failure behavior.
- Formatting and strict Credo passed for all seven changed Elixir files (adapter, context, Metadata, controller, and three test modules). Read-only review found the permissive Thing numeric-prefix parsing mismatch; strict validation and its regression now pass. Final review, including lint cleanup, found no outstanding defects. Old public adapter detail names and list_browsable are absent from live lib/test sources.
- The new `MIX_ENV=test just check` run used the existing Nix-store just binary and ran 853 backend tests with one failure, the same unchanged planned-stage constraint assertion at `test/d20/games/game_test.exs:62`. Full Credo again reported only the three existing Koala nesting findings at lines 250, 345, and 383. Compilation and formatting passed; the composite stopped at mix ci. Its later frontend steps are not claimed to have run. The focused frontend checks above passed; previously recorded unrelated full frontend failures were not rerun separately for this backend continuation. Broad log: `/tmp/d20-hot-provider-just-check.log`.
- Native archive initially rejected abbreviated rename labels without mutating files. Corrected the three mappings to exact `### Requirement:` labels, then native `openspec archive unify-game-listing-options --yes` synchronized all five capabilities and archived the same change. The nonblocking warning about more than ten deltas was retained because this extends the existing delivery outcome. Strict post-archive validation passed all 82 items, lifecycle validation passed nine active changes, and the completed change is absent from the active list. Whitespace checks pass, HEAD remains `7535b35`, and the index is empty. All code and artifacts remain unstaged/uncommitted; issue #272 remains Open/In Progress for user review.

## Provider argument naming cleanup (2026-09-09)

- [x] Use `id` and `ids` for adapter parameters and local identity variables, including the Hot selection; preserve provider fields and error atoms.
- [x] Provider tests passed all 23 tests; adapter formatting and focused strict Credo passed. This non-behavioral cleanup requires no capability delta or new change. All earlier changes remain unstaged and uncommitted.

## 9. Restore dedicated single-game fetching

- [x] 9.1 Add fetch_game(id) returning one map or not-found/source error through shared fetch_games([id]); preserve id/ids names and existing batch behavior.
- [x] 9.2 Switch local single-game metadata enrichment to fetch_game and preserve empty-metadata fallback; verify singleton, missing, invalid, and source-error cases with focused adapter/context/controller tests.
- [x] 9.3 Run touched formatting and strict Credo, review the narrow diff, and reconcile issue/evidence for native synchronization/archive. Run required strict and lifecycle checks after archive; keep all changes unstaged/uncommitted.

Earlier provider/listing evidence remains historical; this narrow single-result boundary does not require repeating unrelated broad-suite failures or frontend checks. Prior deltas are normalized against their already synchronized headers so the same change can be archived again.

## Dedicated single-game fetch verification

- Added fetch_game(id) map/not-found boundary and switched local single-game metadata enrichment to it while retaining fetch_games scalar/list results and all fallback policies. Focused provider, catalog, and controller suites passed 117 tests. Added validation for invalid singular input and unsolicited identities, and preserved scalar batch behavior coverage. Current lowercase hot logger wording was preserved and its existing test expectation aligned.
- Formatting and strict Credo passed for the three touched Elixir files. Parent reviewed the narrow function addition, delegation, errors, and context fallback. No unrelated behavior changed; broad-suite limitations recorded above remain applicable and were not rerun for this narrow change.
- Native synchronization/archive succeeded for the same change; strict validation passed all 82 items, lifecycle validation passed nine active changes, and the change is absent from the active list. HEAD remains 7535b35, the index is empty, and diff whitespace checks pass. All changes remain unstaged and uncommitted for user review.

## Inline Hot fetching readability cleanup (2026-09-09)

- [x] Inline Hot detail fetching and fallback in fetch_hot_games under one with flow, remove fetch_hot_details, and preserve limit/error/identity/order behavior.
- [x] All 26 provider tests passed; adapter formatting and strict Credo passed. Parent reviewed the zero-limit short circuit and discovery/detail error distinction. No capability behavior changed, so no new delta or lifecycle reactivation is needed. All changes remain unstaged/uncommitted.

## 10. Use one Hot with and default invalid provider limits

- [x] 10.1 Move detail fetching into the common with, propagate operation errors, remove adapter error fallback/logger, and preserve successful omitted-item fallback.
- [x] 10.2 Use provider limit 32 for missing, negative, and invalid values; preserve zero and positive cap 100, update list_by_provider documentation, and leave local query normalization unchanged.
- [x] 10.3 Verify provider/context/controller negative/default/zero cases and detail-error propagation with focused tests; run touched formatting and strict Credo.
- [x] 10.4 Review and reconcile issue/evidence and ready deltas for native archival, then run post-archive strict/lifecycle checks. Keep all changes unstaged/uncommitted.

This continuation supersedes the earlier whole-selection fallback on detail-operation errors. The prior broad-suite limitations remain recorded; this scoped behavior correction requires focused checks rather than repeating unrelated failures.

## Common with and provider limit verification

- fetch_games now participates in the Hot with chain; adapter detail-operation errors propagate through list_by_provider, and the existing controller error branch returns empty Games while preserving Playable. Removed the adapter logger/fallback branch. Successful omitted-ID fallback remains covered.
- Provider missing, negative, and non-integer limits use 32; zero still avoids credentials/HTTP, positive limits cap at 100, and local list/playable normalization is unchanged. Updated list_by_provider documentation and nearby cases.
- The focused provider/context/controller suite passed 118 tests. Formatting and strict Credo passed all five touched Elixir files. Parent reviewed the single with, errors, map assembly, limit guards, and tests. No unrelated code was changed; prior broad-suite limitations were not rerun for this scoped correction.
- Native synchronization/archive completed for the same change. Strict validation passed all 82 items, lifecycle validation passed nine active changes, and the change is absent from the active list. HEAD remains 7535b35, the index is empty, and whitespace checks pass. All code and artifacts remain unstaged and uncommitted.

## 11. Normalize provider limits to a positive size

- [x] 11.1 Default missing, nonpositive, or noninteger provider limits to 32 and retain positive cap 100; remove redundant Hot with positivity/false branches and update list_by_provider docs without changing local list normalization.
- [x] 11.2 Verify zero/default and credential behavior with focused provider/context tests, run touched formatting and strict Credo, and reconcile issue/evidence for archival and required post-archive checks. Keep all work unstaged/uncommitted.

The provider zero-limit shortcut is superseded. This narrow correction uses the same owning change and does not repeat unrelated broad checks.

## Positive provider limit verification

- Provider normalization accepts only positive integers, caps at 100, and uses 32 for all other limit values. Removed the redundant with check and else branches. list_by_provider documentation and zero-limit/default/credential tests are updated; local list/list_playable zero behavior is unchanged.
- All 64 focused provider/context tests passed; touched four-file formatting and strict Credo passed. Parent reviewed the guard, direct error propagation, and zero/default test coverage. No unrelated broad tests were rerun for this narrow correction.
- Native synchronization/archive completed at archive/2026-09-09-unify-game-listing-options (the native date advanced). Strict validation passed all 82 items, lifecycle validation passed nine active changes, and this change is absent from the active list. HEAD remains 7535b35, index empty, and whitespace checks pass. All changes remain unstaged/uncommitted.

## Local entry lookup naming (2026-09-09)

- [x] Rename local_by_bgg_id to entries_by_bgg_id and matched local to entry in list_by_provider without changing selection or optional enrichment.
- [x] All 38 catalog tests, Games formatting and focused strict Credo passed. Parent reviewed the renamed bindings and compared the index byte-for-byte with its initial snapshot. The user-staged Metadata/provider files remain intact; the context rename remains unstaged. No behavior/spec delta or lifecycle reactivation is needed.

## 12. Plan internal provider detail navigation (2026-09-09)

- [x] 12.1 Reactivate the same #272 change, inspect current context/controller/home/detail contracts, and update proposal, design, and seven capability deltas for internal provider details.
- [x] 12.2 Record exact-slug-first then provider-fetch precedence, non-null context-generated route slugs, provider-only props/errors/Session denial, and the explicitly deferred Play replacement.
- [x] 12.3 Make catalog route slugs non-null in Games and update serialization/types/fixtures without changing numeric BGG catalog identity, nullable stage, membership, order, or local listing options.
- [x] 12.4 Extend context detail resolution with exact local slug precedence, strict positive decimal fallback, and fetch_game-based provider-only results. Return the normalized route slug from the context; preserve local TypeIDs, enrichment fallback, visibility, and persisted-only Session/module lookup boundaries without database writes or an extra local BGG-ID lookup.
- [x] 12.5 Update the detail controller and prop types for provider-only null local identity/stage, can_launch_game false, schema/session null, source-error 404 mapping, and invalid-Session redirect behavior. Preserve local launch policy and existing Session access; keep Session creation persisted-slug-only.
- [x] 12.6 Replace home external-URL/conditional-attachment branches with uniform internal Inertia anchors using entry.slug. Remove unused fromAction imports and update home/detail frontend fixtures/tests for numeric internal links and no provider-only Play, form, Lobby, or replacement CTA.
- [x] 12.7 Cover backend route-slug production, exact numeric local slug precedence, local row under a different slug, hidden same-BGG rows, invalid/leading-zero numeric IDs, direct provider details, missing/error/sparse metadata, no persistence, denied provider-only Session POST, and invalid Session query handling. Preserve local visibility/launch/existing-Session regression coverage.
- [x] 12.8 Run `mix test test/d20/games_test.exs test/d20_web/controllers/page_controller_test.exs`, touched `mix format` checks, and focused strict Credo. Run home/detail unit tests with `bun run test:unit -- tests/pages/home/ui/home.test.ts tests/pages/game/ui/game.test.ts`, home browser tests with `bun run test:browser -- tests/pages/home/ui/home.browser.test.ts`, touched frontend format/lint, and `bun run typecheck`. Verify canonical accessible links and existing detail layouts; reuse the DevTools workflow for live checks and identify the validated checkout.
- [x] 12.9 Review the route/props boundary and run native `just check` for this cross-stack implementation, recording actual outcomes separately from historical unrelated failures. Reconcile issue #272 and the overlapping unsynchronized #223 game-detail headers without restoring local-only behavior; then synchronize/archive this change and run `openspec validate --all --strict --no-interactive`, `mix openspec.check`, and active-list verification only after implementation and required validation are complete. Preserve the user-managed index and do not commit without authorization.

## Internal detail planning verification

Planning was completed before the separate implementation request. The user has now approved the specified behavior and confirmed string-valued route slugs. Earlier checked tasks and test counts remain historical evidence; new implementation tasks require their own verification. Preserve the initial four-file staged index exactly. The future replacement for Play remains explicitly outside scope.

Planning validation: `openspec validate unify-game-listing-options --strict --no-interactive` passed; `openspec validate --all --strict --no-interactive` passed all 83 items; `MIX_ENV=test mix openspec.check` passed for 10 active changes. Native `openspec status --change unify-game-listing-options --json` reports all four planning artifacts complete. `openspec list --json` retains this active change with 46 of 53 tasks checked, including the seven pending implementation/validation tasks. These checks established planning readiness and do not validate the later implementation.

## Internal detail implementation verification (2026-09-09)

- Catalog `slug` is a non-null string provided by Games. Exact local detail slugs resolve first; a missing positive decimal route ID loads the existing fetch_game boundary and validated runtime Metadata. The explicit context result carries optional entry, normalized slug, and metadata without synthetic persistence.
- Provider-only details use null local identity/stage/schema/session and cannot launch or attach a Session. Local detail visibility, launch eligibility, metadata fallback, TypeID identity, and existing Sessions retain their behavior. Uniform internal Inertia anchors replace external BGG selection and conditional attachments; detail markup is unchanged apart from nullable identity/stage prop types.
- `mix test test/d20/games_test.exs test/d20_web/controllers/page_controller_test.exs` passed 103 tests. Four touched Elixir files pass formatting checks and focused strict Credo. Cases cover empty persistence, sparse metadata, exact numeric collisions, same-BGG records under another slug, hidden local visibility and existing Session access, normalization, invalid IDs without HTTP, source errors, and provider-only Session denial.
- `bun run test:unit -- tests/pages/home/ui/home.test.ts tests/pages/game/ui/game.test.ts` passed 25 tests. `bun run test:browser -- tests/pages/home/ui/home.browser.test.ts` passed seven tests with one existing Firefox reduced-motion skip. Existing screenshot baselines are unchanged. Focused ESLint/Oxfmt and `bun run typecheck` pass with zero type errors or warnings. Browser tests exercise the mocked Inertia boundary, not an authenticated live BGG request.
- Read-only implementation review found no defects. The older #223 game-detail delta and rename are reconciled to the same local/provider contract, with its separate Infra/rollback tasks left open.
- DevTools `list_pages` found no prepared D20 page. Requested the worktree URL while automatic verification continued; no unrelated page or user server was changed. Live-worktree verification is not claimed.

- `MIX_ENV=test /nix/store/ni2dxycnhsp34y4qy6q44nw6pp6bj0l0-just-1.58.0/bin/just check` ran the full backend suite: 868 tests, one failure in unchanged `test/d20/games/game_test.exs:62`, which expects games_stage_domain but receives games_launch_stage_requires_engine. Full Credo again reports only the three unchanged Koala nesting findings at lines 250, 345, and 383. These match the previously reproduced unrelated failures. The composite is not green and stops at mix ci; later composite steps are not claimed to have run. Focused frontend validation above was run separately. Log: `/tmp/d20-provider-detail-just-check.log`.
- Final code review and the subsequent #223 artifact reconciliation review found no outstanding findings. Both active change validations pass. All requested implementation and focused verification are complete; native synchronization/archive and post-archive checks follow as the delivery lifecycle. No authenticated live provider call or prepared live-worktree page was available, and neither is claimed.

- Native `openspec archive unify-game-listing-options --yes` synchronized all seven capabilities and archived the same change at `archive/2026-09-09-unify-game-listing-options`. Strict post-archive validation passed all 82 items; `MIX_ENV=test mix openspec.check` passed for nine active changes. This change is absent from `openspec list --json`. The archive tool's added EOF blank lines were removed from the seven synchronized specs, and game-detail Purpose now includes provider-only routes.
- Final HEAD remains `7535b35`; the initial staged diff matches byte-for-byte, all new implementation/artifact edits remain unstaged, and whitespace checks pass. Issue #272 remains Open/In Progress for user review; no commit, publication, or server-state change was performed.

## 13. Inline fallback and delegate raw route strings (2026-09-09)

- [x] 13.1 Reactivate the same #272 outcome and reconcile context/provider/detail deltas for direct raw-string fetching and inline metadata assembly; preserve the existing user-managed index.
- [x] 13.2 Inline the missing-local-record with in Games.fetch_by_slug, remove fetch_provider_detail and input regex/Integer.parse, pass slug directly to fetch_game, and build canonical result slug from returned attrs.bgg_id.
- [x] 13.3 Add string fetch_game support through existing bounded request/parser behavior, preserve positive integer and batch contracts, and update focused provider/context/controller tests for raw encoded params, returned identity, no/multiple/invalid results, errors, and existing local priority/Session policy. Run focused tests, touched formatting and strict Credo.
- [x] 13.4 Review the narrow diff, reconcile issue/evidence and matching deltas, synchronize/archive the same change, then validate strict OpenSpec and lifecycle state. Preserve current staged files and create no commit.

This continuation supersedes earlier application-side route syntax rejection and the single-use provider-detail helper. No frontend, route shape, availability policy, new provider configuration, cache, retry, or new result structure is introduced. Earlier broad-suite failures remain historical and are not rerun for this focused correction.

## Raw provider slug verification (2026-09-09)

- Games.fetch_by_slug now inlines one with in the missing-record branch: fetch_game(slug), Metadata.new(attrs), and the existing result map with the returned attrs.bgg_id as its decimal slug. Removed fetch_provider_detail and all context input regex/integer parsing. No controller or frontend product change was needed.
- Binary fetch_game calls use the existing bounded batch/request/parser path with the original encoded id value, accepting exactly one parsed game. Integer fetching retains requested-identity filtering and fetch_games retains its existing validated batch contract.
- `mix test test/d20/games/sources/board_game_geek_test.exs test/d20/games_test.exs test/d20_web/controllers/page_controller_test.exs` passed 132 tests, including the existing task timeout. All five touched Elixir files pass formatting and focused strict Credo. Tests prove verbatim raw params, fixed independent query fields, returned-ID canonicalization, missing/invalid/multiple responses, source errors, and preserved local precedence/Session behavior. Controller test fixtures now return no items for unknown IDs rather than returning Qwinto indiscriminately.
- Parent reviewed the inline branch, new binary provider clause, error propagation, and test changes. The initial user-staged index remains unchanged. Prior unrelated broad-suite limitations remain recorded and were not rerun for this narrow backend refinement. No authenticated live BGG request was made.

- Native synchronization/archive completed for the same change. Strict validation passed all 82 OpenSpec items; lifecycle validation passed nine active changes and the change is absent from the active list. Initial staged diff is byte-identical, HEAD remains 7535b35, and whitespace checks pass. All new edits remain unstaged and uncommitted.

## 14. Remove provider ID validation and inline deduplication (2026-09-09)

- [x] 14.1 Reactivate the same #272 change and reconcile the provider design/delta for unvalidated supplied values, one singular fetching path, and parsed response ordering; preserve the current user-managed index.
- [x] 14.2 Remove ID guards, Enum.all?, invalid_bgg_ids, true/false validation branches, and separate string/integer fetch_game paths. Pass Enum.uniq(ids) inline to fetch_batches, return parsed provider items directly, and collect ordered batches without reversal while preserving the empty-list shortcut and source errors.
- [x] 14.3 Verify scalar/list/mixed values, raw request serialization, inline exact-value deduplication, provider-returned identity/order, singular absent/ambiguous errors, empty-list behavior, concurrency/timeouts, and unchanged local/Hot membership with focused provider/context/controller tests. Run touched formatting and strict Credo.
- [x] 14.4 Review and reconcile evidence/issue, synchronize and archive the same change, then run strict OpenSpec/lifecycle validation and check index/HEAD preservation. Leave new edits unstaged and create no commit.

This continuation supersedes earlier integer-only batch validation and response-to-input identity filtering/order restoration. Request batching, metadata parsing, source-error semantics, local/Hot selected membership/order, UI, and persistence are unchanged. Missing successful batch results remain an empty list; the singular operation converts absence or ambiguity into game_not_found.

## Provider input delegation verification (2026-09-09)

- fetch_game has one path through fetch_games([id]). fetch_games retains empty-list, list-shape, and scalar-wrapping clauses; it loads credentials then directly calls fetch_batches(Enum.uniq(ids), api_key). Removed ID guards, Enum.all?, invalid_bgg_ids, true/false input-validation branches, and requested-identity response filtering.
- The ordered reducer appends batches in request order while preserving provider item order and duplicates within each response. Existing Games/Hot callers still select and order their own catalog entries. Parser validation and HTTP/concurrency/timeout/cancellation behavior are unchanged.
- `mix test test/d20/games/sources/board_game_geek_test.exs test/d20/games_test.exs test/d20_web/controllers/page_controller_test.exs` passed 133 tests. Provider and provider-test formatting plus focused strict Credo passed. The batch-order regression passed again after adding explicit descending range steps to remove compiler deprecation warnings. Only the provider implementation and its tests changed in this continuation; context/controller/frontend product files are unchanged.
- Parent reviewed the single fetching path, raw serialization, inline deduplication, batch accumulation, caller membership/order, and test evidence. No outstanding defect was found. Earlier unrelated broad-suite failures were not rerun for this scoped backend refinement; no live BGG request is claimed.

- Same-change synchronization/archive completed. Strict validation passed 82 OpenSpec items, lifecycle validation passed nine active changes, and the change is absent from the active list. Original staged index and HEAD 7535b35 are unchanged; final whitespace checks pass and no commit was made.

## Commit and local master transfer authorization (2026-09-09)

After reviewing the accumulated implementation, the user explicitly requested commit and transfer to master. This supersedes the earlier no-staging/no-commit review constraint. All implementation tasks above are verified and the change is archived; the source branch also includes the previously committed stage-policy and naming steps. Commit this implementation, tests, fixtures, synchronized specifications, and archive together, then validate and integrate the unpublished candidate linearly into local master. The final read-only review found no unrelated changes or outstanding defects. Integration evidence and any retained worktree limitation are recorded in issue #272; remote publication is not part of this request.
