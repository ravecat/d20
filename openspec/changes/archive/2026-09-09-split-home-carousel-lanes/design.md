## Context

Owning issue: [ravecat/d20#272](https://github.com/ravecat/d20/issues/272), Open/In Progress in [D20 Project 5](https://github.com/users/ravecat/projects/5). The exact base is `64f6e824457f2f9540ea3c08d32e087ac79d341e` in `/home/max/apps/d20/.worktrees/work3`, branch `worktree/work3`.

The base component derives one `browseSlides` sequence from all `games` and renders it twice. Hero entries are links; the entire compact viewport is inert and decorative. One group-level `--n` and singleton flag drive both tracks. CSS combines a stepped whole-sequence transform with a one-card translation. Current movement is a five-second dwell plus 600ms using `cubic-bezier(0.22, 0.61, 0.36, 1)`. The just-delivered centering fix uses a relative compact-track offset and `2n + 1` rendered slides for short-loop coverage.

Backend sampling is already sufficient, as verified from code and existing tests:

- `PageController.home/2` calls `Games.list_by_provider()` and serializes its flat ordered result.
- `Games.list_by_provider/1` preserves provider membership/order and joins optional visible local fields.
- `BoardGameGeek.Parser.parse_hot_games/1` keeps unique positive IDs; `fetch_hot_games/1` uses `Enum.take_random(ids, limit)`, default 32. Missing detail metadata preserves selected identity on successful responses; operation errors yield empty Games at the controller.
- Existing tests cover uniqueness/invalid Hot IDs, default and small limits, empty Hot, errors, independent Playable membership, and the 32-card controller boundary (`board_game_geek_test.exs`, `games_test.exs`, `page_controller_test.exs:343`). No new backend behavior or test framework is needed.

The archived centering proposal contains premature disjoint/motion bullets, but its design, delta, completed tasks and product diff do not implement them. The authoritative `home-game-discovery` spec still requires repeated Games rows. A new linked change, rather than reopening that archive, owns these changed requirements. Active footer #268 and catalog-administration #223 changes have separate acceptance boundaries and no owning home-carousel delta.

Since this worktree was created, primary master amended the delivered centering and the same five-second dwell plus 1.1-second movement into `d9335ba6a81c5cda92158402b96419357b241ee7`. Keep this worktree and its original base intact during implementation; reconcile that target before any later authorized transfer.

## Goals / Non-Goals

**Goals:** Losslessly partition the sampled response 1:3; make both lanes' real cards navigable; share a gentler per-card cadence with lane-local wraps; preserve compact centering, internal routing, focus, pauses, metadata fallback and reduced motion; provide focused executable and natural-playback evidence.

**Non-Goals:** New provider sampling or request history; deduplication against Playable; changed public props/routes/limits; new libraries, snippets or extracted carousel abstraction; JavaScript clocks, observers or selection state; manual navigation controls; redesigning cards, shell or Playable selection; migrations, Session/iframe changes, deployment or remote publication. The latest user request authorizes committing and transferring this delivery to local master.

## Decisions

### 1. Derive two contiguous presentation lanes locally

Use inferred Svelte `$derived` values from typed `games`: hero is `games.slice(0, Math.ceil(games.length / 4))`; compact is the remaining suffix. Do not mutate, shuffle, filter, deduplicate or fetch. Concatenating the canonical lanes reproduces the input exactly, including missing metadata and server-provided slugs. Array slicing is presentation, not a new backend grouping contract. Fixed eight-card hero selection would starve small responses; modulo distribution would alter the requested contiguous order.

| Total Games | Hero | Compact | Moving lanes |
| --- | --- | --- | --- |
| 0 | 0 | 0 | None; omit Games section |
| 1 | 1 | 0 | None; hero only |
| 2 | 1 | 1 | None; two independent static cards |
| 3 | 1 | 2 | Compact only |
| 4 | 1 | 3 | Compact only |
| 5 | 2 | 3 | Both, unequal loop lengths |
| 8 | 2 | 6 | Both |
| 31 | 8 | 23 | Both |
| 32 | 8 | 24 | Both |

The distribution is based on delivered count, not requested capacity. No rule promises a different sample on the next request. Playable remains independent even when it shares a BGG ID with Games.

### 2. Lane-local cardinality, group-wide pause and cadence

Move count/singleton inputs to the lane/viewport scope for both Games lanes and adapt shared selectors consistently for Playable. Each track resolves its own `--slide-count`, renamed from `--n` for readability without changing the formulas; an empty lane is absent and a singleton renders one unduplicated static card. Retain the existing Games group as the common hover/focus pause scope and motion-cycle owner. Do not give the two lanes a common *total* duration: their common one-card cycle is 6.1 seconds, while sequence durations are `laneCount * 6.1s` with `steps(laneCount, jump-end)`.

At cycle `k`, the hero origin advances by `k mod heroCount` and compact origin by `k mod compactCount`. The compact settled center remains the second entry relative to its origin, not necessarily its first entry. At 32 games, full-loop periods are 48.8s (8 hero) and 146.4s (24 compact), excluding paused time. Both moving lanes start together and share normalized progress through each movement; their physical travel distances differ. Singleton lanes do not move to mimic their animated sibling. Keep the existing shared CSS cadence for Playable as well, without coupling its independent pause scope to Games.

Keep the minimal doubled sequence plus first-card tail for every multi-item lane, with only the first `n` entries canonical. For rendered size `2n + 1`, retain stepped loop travel `-100% * n / (2n + 1)` and one-card interpolation `-100% / (2n + 1)`. These fractions include gaps and avoid accumulating fractional-width errors. Each step and interpolation reset must coincide, including when one lane wraps and the other merely advances. Replacing this with `-50%`, leaving total Games count on a child lane, or sharing equal total durations would break continuity or cadence.

### 3. Soften the existing movement, not the architecture

Set the shared cycle to 6.1s; hold translation at zero through `5 / 6.1 * 100 = 81.967213...%`, then translate one card over 1.1s using `ease-in-out` (`cubic-bezier(0.42, 0, 0.58, 1)`). Keep stepped transform timing separate. The two-part CSS clock remains sufficient: no library, JS timer, experimental carousel API, new CSS registration, or frame synchronization is justified.

The timing is the approved D20 starting target and acceptance baseline, not a measured Apple duration. Natural playback must look less abrupt, without an end snap, bounce, skipped card or long inert gap. A different material timing choice requires recording the revised decision before delivery, not silently claiming these values were verified.

Primary guidance consulted on 2026-09-09:

- [Apple HIG: Motion](https://developer.apple.com/design/human-interface-guidelines/motion), read via its [official documentation data](https://developer.apple.com/tutorials/data/design/human-interface-guidelines/motion.json): motion should support content without distracting, remain optional, and not prevent interaction. This supports restrained movement and preserved reduced-motion/focus access, not a particular carousel duration. The supplied [Apple homepage](https://www.apple.com/) is aesthetic context only; no homepage timing measurement was performed.
- [W3C CSS Easing Functions Level 1](https://www.w3.org/TR/css-easing-1/) and [MDN animation-timing-function](https://developer.mozilla.org/en-US/docs/Web/CSS/animation-timing-function): standard easing and keyframe-specific interpolation; `ease-in-out` starts slowly, accelerates, then slows.
- The existing manifest's browser policy resolves to `chrome121 edge121 firefox128 ios17.4 opera107 safari17.4`. Use the existing CSS baseline and compatibility checks, not scroll-driven or experimental carousel features.

### 4. Promote compact real cards to canonical links

Remove the all-inert/all-hidden compact viewport treatment. Its first `compactCount` slides use the same ordinary internal Inertia link behavior, metadata fallback, and meaningful names as hero cards. Every Games slide, including loop copies, retains a normal internal anchor and Inertia action. Do not apply `inert` to either Games lane or its copies. Put `aria-hidden` on loop-copy slides and `tabindex="-1"` on their anchors so pointer activation works while only canonical links enter sequential keyboard navigation. Playable keeps its existing inert-copy behavior. Keep BGG-based keyed entries unique across canonical and duplicate markup. Set each card link's `aria-label` directly to `title || "Open game"` in Playable, hero and compact lanes, removing per-card `titleId`, heading IDs and card `aria-labelledby`. Preserve section-heading IDs and their naming relationships; do not add nested interactive elements or positive tabindex.

There is exactly one accessible link per Games input entry, in hero-then-compact response order. Preserve local and numeric slugs verbatim. Metadata remains display-only: missing names use `Open game`, null stage is neutral, and in-development compact cards retain readable names and badges at narrow widths. Do not assume a compact card's canonical hero copy exists anymore.

Retain shared hover/focus pause, but apply overflow and transform/translate/compact-offset reveal overrides only to keyboard-visible focus using `:has(:focus-visible)`; native focus scrolling must fully reveal every canonical link and its focus outline in either lane, including the last compact game. Give each card a nonnegative inline scroll margin of half the viewport space left by its card width, derived from existing lane geometry. This expands the native focus-scroll target to the viewport and prevents a partially visible trailing card from remaining clipped; hero cards need zero margin. During keyboard-visible focus, give the viewport 25% inline scroll padding so the native optimal viewing region is its central half; this also makes Chromium reveal the complete focused compact card. [CSS scroll margins](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/scroll-margin) provide this native scroll-target region without scripted scrolling. On leaving Games, clear temporary focus scrolling and restore centered composition with held clocks. Reduced motion removes animations and nonessential transitions but must retain this complete keyboard route through both lanes. Visible Games loop copies must navigate on pointer activation just like canonical cards; they cannot be the sole keyboard-accessible representation of any assigned game. Pointer focus must preserve the held track position through pointer down/up so the target does not move before its click. Verify clicks on currently visible copies without seeking animations or forcing clicks on hidden content.

### 5. Preserve geometry and separate behavioral tests from motion evidence

Keep shell widths, landscape proportions, responsive gaps and hero geometry. Apply compact centering based on the *lane's* multiple-item state and count: initial center is its second assigned game, with symmetric partial neighbors. Retain unduplicated singleton geometry; a two-game total response now has a static singleton in each lane, not a two-item centered compact loop.

Use existing Home Storybook screenshots and semantic play assertions for the split matrix, exact response order/membership, route/name/stage fallback, empty sections and allowed section overlap. Remove the redundant Home jsdom suite after migrating its application coverage. Keep separate browser tests only for native Tab/Shift+Tab focus reveal with screenshots, real clipped-card pointer/Enter event delivery, and reduced-motion presentation through the existing CDP harness. Storybook userEvent cannot establish native scrolling and hit testing, and the click-action mock proves application wiring rather than the Inertia engine. Remove duplicate singleton browser screenshots now covered by a shared-singleton story. Do not assert loop-copy counts, inert ancestry, exact tabIndex/aria-hidden values, action binding per copy or duplicated badge counts. Use named semantic lanes; avoid new test-only hooks or global harness changes. Update only affected Home stories/fixtures/screenshots.

Preserve the authoritative testing policy: no automated animation-object queries, playback seeking, timing/property assertions, computed-style/geometry assertions, or exact CSS-variable checks. Screenshot defaults intentionally suppress motion. Natural-playback manual evidence is a separate required delivery task, not an automated interpolation test.

Required running-browser review uses actual work3-rendered markup and CSS, recorded URL/build provenance, viewport and reduced-motion state. Observe 5-card (2/3) unequal wraps, 3-card (1/2) two-item compact wrapping, and 32-card (8/24) complete compact wrap, including intervening hero-only wraps. With motion enabled and no hover/focus, wait through natural advancement; record observations or a recording showing shared onset/settling, smooth starts/stops, no gap/jump, and preserved compact centering. Exercise shared hover pause, focus entry after advancement, movement between lanes, exit/resume, and reduced-motion keyboard reachability. Inspect relevant console errors and separate unrelated noise.

Do not restart or repurpose the existing master/source server. The latest completion request authorizes the necessary temporary work3 Storybook server and validation within the existing D20 development tab. Record and restore the original page URL and stop the task-owned server before worktree retirement. An exact CSS-only preview on master is not sufficient for this markup/membership change. Keep the manual review limited to application appearance and interaction; do not introduce automated animation-engine assertions.

## Risks / Trade-offs

- [Lane count accidentally inherited from Games total] → Scope count/singleton per viewport and cover 2, 3, 5, 31 and 32 inputs.
- [Short compact loop runs out of visual runway] → Retain the extra accessibility-hidden tail and rendered-track fractions; observe a two-item compact loop naturally.
- [24 compact entries become inaccessible behind an inert ancestor or after movement] → Canonical compact links and complete Tab/Shift+Tab verification, including reduced motion and focus after advances.
- [Screenshot success conceals a movement discontinuity] → Require natural playback through both independent loop boundaries before completion.
- [Autoplay accessibility remains limited] → Preserve hover/focus pause and reduced motion, do not claim persistent manual pause or full carousel-pattern/WCAG conformance; adding new controls is outside the approved CSS-only scope.
- [Existing unrelated repository checks fail] → Record exact failures, do not repair unrelated schema/Credo/layout/other-game screenshots or broaden this change. Historical #272 failures are not claimed as current work3 test results.

## Migration Plan

No data, API or operational migration. Implement and validate only in work3, then record verified evidence on #272. After all delivery tasks pass, synchronize this delta and archive the new change through the native lifecycle, preserving the old centering archive. Rollback reverts the new completion commit on master, retaining the centering and motion cadence from `d9335ba6`. After the requested review and validation, synchronize/archive this change, commit the cohesive delivery, rebase it onto the pinned local master tip and fast-forward master. Validate the integrated target and then retire the source worktree/branch. No remote publication or deployment is included.

## Open Questions

None. Implementation is authorized. The user clarified that every visible Games card, including loop copies in both lanes, must navigate to the game detail page.

## Specification-stage baseline

- Primary and source checkout were clean; requested path and branch were absent; `.worktrees/` was ignored by common Git `info/exclude`. Created registered `worktree/work3` from the exact requested commit.
- Initialized work3-only ignored dependencies with `mix deps.get` and `cd assets && bun install --frozen-lockfile`; no tracked manifest/lockfile changes. No database or development server was started.
- First Home unit invocation failed before tests with `vitest: command not found` (127), despite a valid local installation. Supervisor approved setup-only investigation. Inherited `BASH_ENV=/home/max/.bash_env` reset child-shell PATH; process-local `env -u BASH_ENV` fixes resolution without editing any configuration.
- Clean baseline: `cd /home/max/apps/d20/.worktrees/work3/assets && env -u BASH_ENV bun run test:unit -- tests/pages/home/ui/home.test.ts` passed 1 file, 9 tests. `git diff --exit-code` and `git diff --cached --exit-code` passed before artifact creation.
- `openspec validate --all --strict --no-interactive` passed all 82 pre-change items. Backend tests, browser playback and screenshots are implementation-stage validation, not claimed as performed by this specification run.

## Final target reconciliation

The source worktree was rebased onto pinned master `d9335ba6a81c5cda92158402b96419357b241ee7` before its completion commit. The only autostash conflict was the carousel explanatory comment; the final component is byte-identical to the previously validated work3 version. The delta also modifies master's soft-cadence requirement so it preserves the delivered timing while specifying independent Games lane loops and pointer-activatable Games copies, avoiding a stale inert-copy requirement after synchronization.

Final validation and manual evidence are recorded in `tasks.md`, including the temporary Storybook motion-reset override, sampled playback limits, native browser evidence and unrelated broad-check failures.
