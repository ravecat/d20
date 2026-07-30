## Context

The registry currently equates catalog membership with playability: every entry requires an `engine` and a non-empty iframe `sandbox`. `D20.Games.list/0` then performs one BGG request per entry, and the detail controller always asks the configured engine for session-creation attributes. This shape cannot represent a planned game that has BGG metadata and a detail page but no local implementation.

The requested catalog grows from four to nineteen games. Qwinto is implemented, Koala Rescue Club is the current work in progress, and the remaining games are catalog-only. Production users need to launch active games, while development and test also need to launch in-progress engines.

## Goals / Non-Goals

**Goals:**

- Separate catalog membership from local engine availability.
- Add optional `active` and `in_progress` registry statuses, with missing status interpreted as inactive.
- Fetch metadata for the expanded catalog efficiently and preserve BGG as the display-metadata source.
- Make availability explicit in home-page props and presentation.
- Keep all configured detail routes browseable while enforcing launch policy in both the rendered UI and POST boundary.

**Non-Goals:**

- Implement engines, iframe modules, or game rules for newly listed games.
- Persist catalog entries or statuses in the database.
- Change session state, channel protocols, iframe contracts, or existing-session behavior.
- Add an administrative status editor or a production feature flag UI.

## Decisions

### 1. Make operational registry fields conditional on status

`bgg_id` remains required for every registry entry. `status` accepts `:active`, `:in_progress`, or `nil`. `engine` and `sandbox` become optional for inactive entries but remain required for active and in-progress entries. This keeps misconfigured launchable games fail-fast while allowing catalog-only records.

Alternative considered: create placeholder engine modules for every game. That would misrepresent planned games as executable and create unnecessary modules whose only behavior is failure.

### 2. Treat status as availability metadata, not display metadata

`status` travels beside the resolved `game` metadata in catalog and detail Inertia props. It does not become part of `D20.Games.Game`, because BGG-derived metadata and application availability have different ownership and lifecycles.

The initial assignments are:

- `active`: Qwinto.
- `in_progress`: Koala Rescue Club.
- inactive: Fliptown, Next Station: London, and all newly added entries.

The requested `railroads` name is resolved as Railroad Ink: Deep Blue Edition (`bgg_id` 245654), matching the roll-and-write context of the requested list.

### 3. Fetch catalog metadata in one BGG request and own default ordering in the context

The BGG adapter will accept a list of IDs and request them as a comma-separated `id` parameter. `D20.Games.list/0` will index the parsed response by `bgg_id`, rebuild entries, and return them in stable availability order: `active`, then `in_progress`, then inactive. Registry order remains the tie-breaker within each group. The complete listing flow stays in one `with` block instead of being split across private helpers. Detail lookup keeps the existing single-ID function.

Alternative considered: retain one request per catalog entry. Nineteen sequential requests increase latency, failure exposure, and upstream API load on every uncached home request.

Alternative considered: return registry order and regroup entries in `home.svelte`. That duplicates catalog policy in a client and makes other consumers receive a weaker default contract.

### 4. Compute one launch-policy boolean at the server boundary

Application configuration will expose `:allow_launch_in_progress`, true outside production and false in production. This is a temporary environment gate until runtime game feature flags or experiments own availability. An active game is launchable in every environment, an in-progress game is launchable only when this flag is true, and an inactive game is never launchable.

The detail controller will send `can_launch_game` to Svelte. When false it will avoid calling an absent engine, send empty creation attributes, and omit the session creation form. Both the page POST action and standalone module bootstrap will independently return `403 Forbidden` before creating a new session when policy denies launch. A standalone module may still reconnect to an existing matching session.

Alternative considered: hide the button only in Svelte. That leaves the POST route usable directly and requires the browser to infer deployment environment.

### 5. Keep catalog navigation enabled for every status

All cards remain anchors to `/games/:slug`. The home page renders catalog entries in the order supplied by `D20.Games.list/0`; it does not filter, regroup, or sort them again.

Active cards retain the full visual treatment. In-progress and inactive cards receive a muted preview treatment; only in-progress cards render a `Soon` text badge. `Soon` is presentation copy for the existing `in_progress` status and does not rename the registry value or change development launch policy. The badge remains outside the dimmed visual layer so its contrast is preserved.

Game titles render as unboxed text directly over the artwork. A subtle left-to-right dark scrim, lighter than the detail-page preview shade, provides contrast without visually separating the title from the game image.

Alternative considered: disable inactive anchors. That conflicts with the requirement that every catalog game has a browseable detail page and removes normal keyboard/link behavior.

Alternative considered: keep the opaque title chip. It guarantees contrast but obscures artwork and makes the title feel detached from the game cover.

## Risks / Trade-offs

- [BGG omits one requested item from a batch response] -> Preserve the current all-or-error catalog contract and report the missing slug as metadata unavailable.
- [Optional engine fields are accidentally used without checking policy] -> Keep engine access inside policy-checked controller paths and validate bindings for every non-inactive entry.
- [The in-progress policy is mistaken for a full session-runtime kill switch] -> Scope the flag explicitly to new in-progress session creation at public HTTP boundaries; active games, existing volatile sessions, and internal session APIs are unchanged.
- [Muted cards become difficult to identify] -> Dim only the artwork layer while keeping title, focus outline, and status badge readable.
- [Status grouping accidentally scrambles catalog order] -> Sort once in `D20.Games.list/0` with a stable status rank and assert the public list and serialized Inertia order.
- [Unboxed titles lose contrast on bright artwork] -> Reuse a lighter form of the detail preview's left-side scrim and retain a restrained text shadow.
- [Railroad title interpretation differs from user intent] -> Keep the BGG ID isolated in config so it can be replaced without changing routes or contracts.

## Migration Plan

1. Extend registry validation and add the in-progress environment launch flag.
2. Add catalog entries and status assignments.
3. Batch catalog metadata lookup and expose statuses through controller props.
4. Update home and detail Svelte pages and tests.
5. Deploy normally; no database or session migration is required.

Rollback reverts the configuration entries, optional registry fields, launch-policy checks, and Svelte prop changes. Existing routes and session records require no cleanup.

## Open Questions

- Confirm whether `railroads` should refer to a different BoardGameGeek entry than Railroad Ink: Deep Blue Edition.
