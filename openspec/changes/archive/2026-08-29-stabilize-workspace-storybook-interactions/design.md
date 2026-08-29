## Context

The Workspace browser harness manually mounts the production component and reconstructs `phoenix-session` state with module mocks. Its keyboard scenario passes in isolation but races keyboard activation and Svelte rendering under Firefox when the complete frontend suite runs. The existing Storybook Vitest integration already renders production Svelte components in three Chromium viewport projects and executes each story's optional `play` lifecycle before visual comparison.

The failure was discovered while validating the backend quality gate in issue #179, but it is a separate frontend test-ownership problem. Issue #254 and this change isolate that correction so backend tooling and frontend behavior coverage can be reviewed independently.

## Goals / Non-Goals

**Goals:**

- Give Workspace keyboard behavior a deterministic production-component Storybook owner.
- Keep the Workspace catalog focused on Auto selection and connection-status states rather than creating one story per former browser test.
- Show Live, Finished, and long-identifier sessions together, with dedicated stories for the shared Reconnecting and Failed transport states.
- Keep the compact status dot and label centered and use one smaller font size for both Live and Finished.
- Preserve the existing Chromium desktop, tablet, and mobile visual matrix.
- Remove the duplicate manual browser harness while retaining lower-layer tests for non-catalog lifecycle and transport responsibilities.
- Keep connected story state explicit, deterministic, and cleaned between stories.

**Non-Goals:**

- Changing production Workspace structure, runtime session state, transports, iframe behavior, or accessibility semantics beyond the requested compact-status presentation.
- Introducing per-session transport statuses that the production Workspace model does not support.
- Creating a dedicated accessibility story; the configured Storybook accessibility addon remains responsible for cross-cutting checks.
- Introducing a production adapter or injectable session store solely for tests.
- Replacing lower-layer Workspace model and presentation tests that verify Phoenix-session configuration and calls, authoritative snapshot behavior, SDK bridge and frame lifecycle, subscription cleanup, or model contracts.
- Moving visual reference ownership away from Chromium.

## Decisions

### Keep four cohesive Workspace stories

The Auto selection story imports the production `Workspace` component and uses accessible role and name queries to verify the initially selected session, Compact restoration, Enter and Space activation, source-order focus movement, fullscreen entry and exit, and switching selection to another session.

The ready connection-status story renders three sessions together: two in-progress sessions, including one with a long identifier, and one finished session. It verifies two Live statuses and one Finished status so its visual reference preserves the meaningful mixed ready state.

Dedicated Reconnecting and Failed stories each render one expanded session with the corresponding shared Workspace transport status. This makes both full-window transport overlays directly reviewable instead of hiding them inside transient `play` transitions. Each story cancels its rendered CSS animations before screenshot capture so window labels, status indicators, and connection spinners remain deterministic.

Separate authoritative-snapshot, frame-preservation, Compact-accessibility, and keyboard-only stories were rejected. Snapshot and frame lifecycle contracts already have lower-layer owners, accessibility is cross-cutting addon behavior, and keyboard interaction fits the Auto selection workflow. This avoids catalog and screenshot proliferation without restoring the duplicated manual renderer.

### Keep compact statuses centered and typographically uniform

The compact status remains one fixed-width inline flex control. Its dot and text group retain the existing centered alignment. The shared status rule reduces the label to `0.6875rem`, preserving one font treatment for both phases and every transport-derived fallback without branching markup or state-specific style overrides.

A per-state width, offset, or font rule was rejected because it would make presentation depend on label length and reintroduce visual drift between Live and Finished. Markup changes and experimental text-metric properties are unnecessary.

### Supply session state at the Storybook module boundary

Storybook aliases `phoenix-session` to a story-only module exposing `set`, `setStatus`, `clear`, and the minimal `session` surface consumed by the production Workspace model. Each story calls `set` with its complete branch-driving session data from `beforeEach`, returns `clear` as cleanup, and invokes direct reactive status setters from `play` when needed.

State literals remain inline at their call sites rather than being hidden behind rendering, descriptor, or empty-state helpers. Every initialization and reset creates fresh nested records.

A production transport adapter or component prop was rejected because the missing seam exists only in the isolated Storybook environment. Storybook's established module-boundary replacement is sufficient and keeps runtime code unchanged.

### Use the existing Chromium Storybook matrix

The existing desktop, tablet, and mobile Chromium projects execute every story's `play` lifecycle before visual comparison. No dedicated Firefox Storybook project or interaction-only tag is added. This keeps behavior and visual ownership on the same established test surface and avoids another browser project solely for the migrated scenario.

### Remove the superseded manual browser harness

`workspace.browser.test.ts` is removed because its manual render and session fixtures duplicate the production-component Storybook seam, while its non-catalog authoritative snapshot and frame lifecycle responsibilities remain covered by existing model and presentation tests. Storybook does not add module spies merely to duplicate lower-layer assertions.

## Risks / Trade-offs

- [Risk] Storybook session state leaks between generated tests. - Require every connected Workspace story to call `set` in `beforeEach` and return `clear`.
- [Risk] Status fixtures imply unsupported per-session transport states. - Keep Live and Finished derived from session phase, and represent Reconnecting and Failed as separate stories driven by the one shared Workspace transport status.
- [Risk] Window labels, live indicators, and connection spinners produce timing-dependent screenshots. - Cancel each Workspace story's rendered animations before visual comparison.
- [Risk] Removing browser scenarios loses unique lower-layer coverage. - Retain model and presentation tests for authoritative snapshots, frame and SDK lifecycle, transport calls, and subscription cleanup.
- [Risk] The smaller uppercase status label becomes harder to scan. - Reduce it by only one CSS pixel, keep the existing high-contrast surface, and review Live and Finished together at all three supported viewports.
- [Trade-off] The Auto selection play function covers keyboard and fullscreen behavior in addition to selection. - Keep those interactions together because they exercise the same Workspace window workflow and avoid a duplicate catalog state.

## Migration Plan

1. Add the Storybook-only `phoenix-session` fixture and alias.
2. Add the Auto selection, ready connection-status, Reconnecting, and Failed stories with twelve reviewed Chromium references.
3. Keep the compact status content centered, apply the shared smaller label size, and regenerate affected references.
4. Remove the superseded manual Workspace browser harness while retaining lower-layer tests.
5. Document connected-story setup and Chromium interaction ownership.
6. Run remaining Workspace tests, Chromium visual projects, complete frontend validation, and strict OpenSpec validation.
7. Sync and archive the validated change, then expose the complete unstaged diff for review.

Rollback restores the removed browser harness, reverts the compact-status style, and removes the stories, fixture, alias, visual references, and documentation updates. No production or data rollback is required.

## Open Questions

None.
