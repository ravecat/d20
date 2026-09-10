## Context

`Games.fetch_by_slug/1` resolves an exact local slug first and otherwise delegates the original string to BGG. Local detail has a TypeID and operational launch policy; provider-only detail has no local identity. `PageController` emits `can_launch_game`, and `game.svelte` shows a Session `Lobby` first, then `LaunchForm` only when launch is allowed and a schema exists. Other successfully resolved pages have no activation action.

`Games.session_launch_available?/1` combines enabled state, configured visible stages, and a supported engine. A false result also covers implemented but disabled games. Numeric provider detail can refer to an implemented game under a different local slug while remaining non-playable by the accepted resolution contract.

The existing accounts system provides persisted user TypeIDs, server authentication, a shared account dialog, and safe return paths. Anonymous actors are session identities with no persisted account row. `Metadata` deliberately contains presentation fields and discards provider `bgg_id`; interest therefore needs resolved identity retained separately from Metadata.

This change owns [issue #275](https://github.com/ravecat/d20/issues/275). The user authorized implementation of the clarified specification, including durable account-only requests, one contribution per account and BGG game, cascading account deletion, and separate SessionForm and InterestForm components.

## Goals / Non-Goals

**Goals:**

- Offer `I want this game!` when a successfully rendered page has no Session and cannot launch.
- Collect durable, deduplicated account demand for the resolved BGG game, including provider-only pages.
- Preserve launch authorization, visibility, local/provider resolution, existing Session behavior, and metadata fallback.
- Expose the current account's saved state, a public per-game request count, and a reliable grouped count source for operators.

**Non-Goals:**

- Engine implementation, promised delivery, availability-reason UI, BGG-to-local reassociation, catalog creation, or metadata persistence.
- Guest voting, automatic submission after login, public rankings, dashboards, notifications, cancellation, or vote weights.
- A persisted `playable` field, compatibility alias, new dependency, generic polling, cache, or separate mutable counter table.

## Decisions

### 1. Rename the page prop without redefining launchability

Emit `playable: boolean` on both local and provider-only responses and consume only that prop. Render local detail directly in its `PageController.render_game_detail/3` clause, including playability, schema, and page props, without a single-use `render_game/4` helper. Keep `Games.session_launch_available?/1` and both existing Session-creation endpoints unchanged. Do not rename internal launch-policy APIs solely to match a display prop.

Select the activation state in this order:

| Page state | Activation content |
| --- | --- |
| Valid existing `session` | Existing `Lobby` with its current descriptor |
| No Session, `playable: true`, schema present | `SessionForm` with existing setup fields and `Play` |
| No Session, `playable: false` | `InterestForm` with its request action or saved state, without game setup fields |
| No Session, `playable: true`, schema missing | Neither form; this remains a launch-contract defect |

The interest copy asks for online availability. It must not explain false launchability as proof of missing implementation. Richer reasons belong to #127.

Use public `Games.visible?/1` for the configured-stage rule on a local Game. Visibility depends only on `stage`; it does not require enabled state or an engine. PageController combines that predicate with its validated existing-Session exception, Interests retains its provider-only nil bypass, and `session_launch_available?/1` combines visibility with enabled state and engine support. Runtime configuration access stays inside Games. Existing list queries keep their stage predicates in SQL before limiting; do not replace those scopes with in-memory filtering or alter ordinary fetch semantics.

### 2. Bind interest to the resolved BGG identity and original route

Extend the internal resolved-detail result with `bgg_id`: use `entry.bgg_id` for an exact local row or the parsed provider response identity after a local miss. Keep it outside presentation `Metadata` and independent of the detail `id` TypeID. Local metadata outages still permit interest because the persisted binding supplies identity.

Add one page prop, serialized from snake_case in the usual way:

```typescript
interest: {
  action: string;
  requested: boolean;
  count: number;
}
```

The server constructs `action` as the internal `POST /games/:slug/interest` route using the original requested slug, encoded by Phoenix routing. `requested` checks the current authenticated account and resolved BGG ID; it is false for guests. `InterestForm` submits the server-provided action with an empty payload. The server resolves the route and uses its current BGG ID; no expected-identity parameter, client ID comparison, or mismatch error is needed. Supplied BGG IDs are ignored.

Preserving the original route matters: `/00183006` may resolve provider game 183006 while an exact local slug `183006` is bound to another BGG game. Reconstructing the POST target from normalized `page.slug` could count the wrong game. Successful and recoverable-error redirects also return to the original detail route, without a Session parameter. If a local BGG binding or provider result changed while the page was open, the new request uses the current resolved identity. This rare case is accepted without a stale-page precondition.

This avoids signed subject tokens or a second resolution algorithm. It leaves the existing normalized `slug` prop, exact-local precedence, raw-string delegation, provider-only behavior, and no-redirect policy intact.

### 3. Store one account request per BGG game and derive counts

Use `D20.Games.Interest` as the schema and `D20.Games.Interests` as the public interest context. Controllers and other callers use `Interests.request(user, slug)`, `Interests.requested?(user, bgg_id)`, `Interests.count(bgg_id)`, and `Interests.counts()` directly. Remove the redundant interest delegates from `D20.Games`, which retains catalog discovery, visibility, and launch policy. Keep the operation documentation and specs on Interests. `Interests.request/2` reuses `Games.fetch_by_slug/1` and `Games.session_launch_available?/1`, with visibility/playability checks directly in its `with` and insert-if-absent directly in its body, without single-use private wrappers. Controllers call `D20.Games.Interests` directly for interest operations. The table is `game_interests` with:

| Column or constraint | Purpose |
| --- | --- |
| `id`, non-null string primary key, represented by an autogenerated `TypeID` with prefix `interest` | Stable typed identity of each request |
| `user_id`, non-null string foreign key to `users.id`, represented by the existing user-prefixed `TypeID` Ecto type, delete cascade | Authenticated account identity; deleting an account removes its contributions |
| `bgg_id`, non-null positive integer | Subject shared by local and provider-only details |
| `inserted_at`, non-null UTC timestamp | Time of the first request |
| Unique index `(user_id, bgg_id)` | One contribution per account/game, enforced under concurrency |
| Index on `bgg_id` | Per-game membership aggregation without a separate counter |

Each request has its own typed primary key, following persisted entity identity conventions. No update timestamp is needed for an append-once association. No `games` foreign key is possible because provider-only details have no catalog row. Do not copy titles, email, actor profiles, or BGG metadata into this table.

An insert with a conflict target matching the account/game unique index is idempotent and preserves the original request ID and timestamp. Only that duplicate is treated as success; invalid identity, foreign-key, and database failures remain failures. Set account identity from the authenticated server user and BGG identity from server resolution, never by mass-assignment of request attributes.

Provide an internal grouped-count query returning only `{bgg_id, count}` from authoritative rows for operator use through the existing trusted application/database access. Expose only the resolved game's count through `interest.count`, using a filtered aggregate in `Interests.count/1`. Return zero when no requests exist. No HTTP listing, dashboard, or cached total is introduced. A removed account immediately stops contributing. Existing requests stay attached to their original BGG ID when a local binding changes or the game becomes playable; they are historical interest, not movable local-record state.

A bare counter was rejected because duplicate clicks and retries could inflate it without a durable uniqueness fact. Anonymous actor storage and later identity merging were rejected for this first version because account-scoped rows meet the accepted requirement with simpler integrity.

### 4. Use a focused authenticated Inertia write boundary

Add `GameInterestController.create/2` behind the existing browser/Inertia protections and authenticated-user requirement, without sudo. A direct unauthenticated POST follows existing authentication-required behavior and cannot write or be replayed after login.

The controller passes the authenticated user and original slug directly to `Interests.request/2`, which checks visibility and launch eligibility in its `with` operation, without private predicate wrappers; missing local entries pass those checks. The context owns resolution, visibility, launch eligibility, and persistence; it returns `:ok` or the existing error tuple. The controller owns redirects, statuses, and user-facing error messages, and may pattern-match an `Ecto.Changeset` error without casting fields or querying the database.

For authenticated requests, the context applies these checks before insertion:

1. Resolve the original slug with the current exact-local-first `Games` boundary. Preserve 404 for missing/provider-failed details.
2. Enforce ordinary detail visibility for a selected local row. A hidden row returns 404 even if launchability is false; a Session query or payload cannot bypass this requirement for interest.
3. Recheck launchability for the selected detail. If it is playable, return `{:error, :game_available}` without writing; the controller silently redirects to the original detail with no error, success, or availability message.
4. Insert the authenticated account/game association idempotently and return `:ok`; the controller issues a 303 redirect to the original detail route. The subsequent response queries persisted membership and the current count; a successful redirect alone does not establish saved UI state.

Duplicate submissions in an eligible state return the same saved result. Previously stored rows remain when launchability changes, but new submissions are then denied. Invalid Session-creation requests retain their existing statuses and errors because the new endpoint never delegates to Session creation.

The controller handles `:ok` and `{:error, :game_available}` with the same plain 303 redirect. Only a saved request produces persisted membership on the subsequent page; a playable no-op does not claim a save. Recoverable persistence errors use the existing Inertia redirect/error mechanism scoped to `InterestForm`, separate from `SessionForm` errors. The error bag is `interest` and its general error field is `message`: page consumers read `errors.interest.message`, while the bag-scoped Form snippet reads `errors.message`. The server assigns `%{message: text}`; no `interest.interest` alias is retained. Unexpected transport failures leave the action retryable without claiming success. A lost response after a committed insert is safe to retry; the unique key prevents another contribution. No interest state is stored in browser storage.

### 5. Separate SessionForm and InterestForm

Rename `LaunchForm` / `assets/js/pages/game/ui/launch_form.svelte` to `SessionForm` / `assets/js/pages/game/ui/session_form.svelte`. Preserve its schema-driven setup, `BasicForm`, `Play` submission, and existing state handling. Update imports and existing test/story consumers; retain no old component export, file, or compatibility alias.

Add `InterestForm` in `assets/js/pages/game/ui/interest_form.svelte` as the alternative submission form. `game.svelte` chooses between the two forms after checking for an existing Session; neither form owns the other's workflow. Initially `InterestForm` has one visible button with the visible label and exact accessible name `I want this game!` and the existing full-width primary CTA treatment. It contains no game-owned setup inputs and does not instantiate `BasicForm`; submission uses `Form` imported directly from `@inertiajs/svelte`, with the server-provided action, `method="post"`, and `errorBag="interest"`. Its `children` snippet supplies `processing` and scoped `errors.message`; retain the page error fallback `page.props.errors.interest?.message`. Its `onBefore` guard cancels already-requested submissions and opens login for guests by returning false, before processing starts. Remove the manual router call, processing state, and lifecycle callbacks.

The button shows the persisted numeric count, including zero, then a decorative five-point SVG star, then its current action label. Reuse the existing metadata star geometry without adding a dependency. Keep the action accessible name unchanged and expose the count as its accessible description. Pending, saved, and retry states retain the count; only refreshed server props update it, without an optimistic increment.

For a guest, activating the button calls the existing shared auth store/dialog with the safe original detail return path. Closing the dialog preserves the page and records nothing. Authentication returns to the detail page; the account must explicitly activate interest to write. Do not queue or replay an anonymous request, require an email on provider-only accounts, or create a second auth dialog.

For an authenticated account, `InterestForm` exposes pending state (`Saving...`, busy and unavailable for repeat activation), then uses `interest.requested` from refreshed props to show the disabled saved action `Requested`. The button label confirms saved membership without a separate success message below it. A server-reported persistence or validation error shows an understandable adjacent alert and restores `I want this game!` for retry. Network errors and unexpected HTTP responses use standard Inertia handling, without a custom inline message or global event hooks; Form clears its processing state when the visit finishes. The user accepts that narrower inline-error scope. Keep the installed 3.6.0 adapter: current stable 3.7.0 has the same Form callback limitation, so an upgrade is not needed for this migration. Suppress stale errors after membership is confirmed. Do not optimistically announce a save before the server-backed membership is known.

Use native button behavior, visible keyboard focus, perceivable pending/saved button labels, a busy indication on the button, and an alert for server-reported form errors. Keep the original control mounted where practical so focus is not discarded by state changes. Do not replace a valid Session Lobby with interest or mount any Session store for provider-only pages.

### 6. Make game-detail activation states reviewable in Storybook

Add `assets/stories/pages/public/game.stories.ts` under the existing route-label convention `Pages/Public/∕games∕:slug`. Render the production `GamePage` inside its wide application layout. Keep the mocked Inertia URL consistent with each story's slug and session descriptor.

Cover playable detail without a Session (`Play`), a waiting Session (`Lobby` and its players/start action), unavailable detail without a Session (`I want this game!`), and authenticated saved interest (disabled `Requested` without a separate success message). Missing Session alone must not imply interest eligibility. Reuse realistic metadata and the existing deterministic transport mocks; extend only the mock lifecycle/state boundary needed by Lobby and reset state between stories. Do not call live Session or interest endpoints. Alias the socket module at the Storybook boundary; exclude the SJSF form/theme packages from dependency prebundling and include their CommonJS jsonpointer dependency, matching the established browser-test package treatment.

Validate activation selection through accessible story assertions, existing page-layout tests, reviewed desktop/tablet/mobile screenshot references and a normal comparison run, frontend lint/type checks, and a Storybook build. Use the existing Storybook browser tab for manual verification. This extends issue #275 and does not resolve its previously recorded delivery blockers.

## Risks / Trade-offs

- Account-only interest adds sign-in friction. Reusing existing authentication limits implementation cost; these totals measure distinct accounts, not unique people.
- Provider-only writes require successful resolution and can fail during a BGG outage. Preserve that error boundary and make retry safe; local bindings remain usable with metadata fallback.
- Numeric provider routes and disabled local games can collect interest for games with existing engines. Counts represent desired online availability, so the UI makes no unsupported claim about implementation status.
- Operators can change catalog bindings after a page is rendered. New submissions use the current route binding without comparing it to page-load state; previously stored rows remain tied to their original BGG ID.
- Interest is historical rather than a queue of currently unimplemented games. No automatic removal occurs on release; operators interpret aggregate counts alongside current catalog state.
- The account/game unique index prevents duplicate requests from one account, not multiple-account abuse. Rate limits and abuse scoring are separate work if observed demand warrants them.

## Migration Plan

1. Generate an additive `game_interests` migration using the native Mix generator; create its typed string primary key, user foreign key, account/game unique index, positive BGG constraint, and grouped-count index. No backfill is needed.
2. Validate the migration and reverse migration against a disposable test database without resetting shared development data. Check user deletion cascades and duplicate concurrent inserts.
3. Deploy the migration before the code that reads or writes interest, then deploy backend props/routes and their matching frontend together because the prop rename has no alias.
4. Validate local/provider CTA selection, authentication, duplicate submission, reload persistence, grouped counts, and unchanged existing Sessions before completing delivery.
5. Roll back application code while retaining collected rows. The reverse migration drops the new table and loses requests, so production data removal is an explicit destructive operation, not a default rollback step.

## Open Questions

No blocking design question remains. The clarified specification is authorized for implementation. Account deletion removes the account's interest rows and decreases derived counts; release alone does not remove historical requests.
