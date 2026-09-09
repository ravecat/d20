## Context

Issue #272 and `worktree/api-game-discovery` own the existing staged and unstaged catalog changes. Local list/playable options, BGG Hot discovery, batching, and catalog maps are implemented and previously verified. Internal provider-only detail pages and context-generated string route slugs are implemented. This refinement removes provider input-ID validation and shares one fetching flow while preserving the delivered local and provider page behavior. Earlier task evidence describes the already implemented steps and does not validate this new behavior.

## Goals / Non-Goals

**Goals:** Keep provider selection independent of persistence; have the context provide one internal route slug per catalog entry; support metadata-only detail pages by numeric BGG ID; preserve local visibility, launch eligibility, and existing Session access; simplify home links to the existing uniform Inertia pattern.

**Non-Goals:** A replacement for Play, new detail layouts, automatic Game persistence, invented TypeIDs or engines, catalog entry structs, new availability flags, full-catalog sampling, provider frameworks, caching, retries, global rate limiting, new dependencies/configuration, migrations, and Session/iframe changes. The user authorized implementation and subsequently approved a semantic commit and local master transfer.

## Decisions

### Preserve local queries and give provider discovery its own entry point

`Games.list/0,1` and `list_playable/0,1` keep their optional native Ecto options and shared private query execution. Playable retains enabled, configured visible-stage, and implemented-engine predicates intersected with caller `where`. Both use default limit 32, clamp integers to 0..100, fall back for non-integers, ignore unknown options, and impose no order unless requested. Home still requests playable limit 8 and `[desc: :stage, asc: :id]`. Replace `list_browsable/0,1` with `list_by_provider(options \\ [])`; its only supported option is `limit`: missing, nonpositive, or non-integer values use 32, and positive values cap at 100. Local listing keeps its existing negative-to-zero rule. Unknown keys, including `where` and `order_by`, are ignored rather than translated into remote behavior. Keep public option shapes inline in typespecs. Reuse actual shared metadata assembly if needed, without new single-use helpers or compatibility APIs.

### Keep dependency direction from context to provider

The call chain is `PageController.home -> Games.list_by_provider -> BoardGameGeek.fetch_hot_games -> BoardGameGeek.fetch_games`. The BGG adapter owns HTTP, XML parsing, selection, batching, and source attrs. It does not call the Games context, Ecto, Repo, or Metadata. Local listing calls `fetch_games`; local single-detail enrichment calls `fetch_game`, replacing both old provider names without aliases.

`fetch_games/1` accepts one supplied value or a list and normalizes only the collection shape. Empty lists return `{:ok, []}` without credentials or HTTP. For nonempty input, load credentials and call `fetch_batches(Enum.uniq(ids), api_key)` directly. Do not validate ID type, positivity, syntax, or requested/returned identity equality; ordinary Enum.join and Req query encoding serialize values for BGG. Do not add a custom serializer or replacement validation layer. Parsed response games are returned in request-batch order and provider order within each response, including provider-returned identities or duplicates. `fetch_game(id)` has one path through `fetch_games([id])`, accepting exactly one parsed game or returning game_not_found for zero/multiple games. Source errors propagate. Local enrichment and Hot already associate response metadata by returned BGG identity and retain their selected membership/order; these caller behaviors remain unchanged.


Provider function arguments and local identity lists use `id` and `ids`; the enclosing module already supplies BGG context. This naming cleanup does not rename normalized `bgg_id` fields or error atoms.

### Select from one Hot response and retain selected identity

`fetch_hot_games(options \\ [])` supports only `limit`, using 32 for missing, nonpositive, or non-integer values and capping positive values at 100. The normalized limit is always positive, so the with starts directly with credential loading without a separate positivity check. It fetches `/xmlapi2/hot?type=boardgame` once using the existing runtime bearer credentials. It parses an `items` root; a different root returns `{:error, :invalid_hot_response}` and malformed XML retains a parse error. Invalid/nonpositive IDs are discarded, remaining IDs are deduplicated, and one random selection chooses at most the normalized limit. An empty valid Hot response returns an empty list. There is no padding, repeated Hot request, inferred pagination, or guaranteed Hot size.

The selected IDs establish membership and order before details load. `fetch_hot_games` invokes `fetch_games` for that selection and returns attrs in selected order, using `%{bgg_id: id}` when details omit an item. Put the fetch_games result match in the same with as Hot loading and parsing. Any detail-operation error propagates unchanged; remove the separate adapter warning and whole-selection error fallback. Only a successful result with omitted IDs receives identity-only attrs. Runtime Metadata construction and optional local joining remain in the context; no private fetch_hot_details helper is needed.

### Batch details with bounded concurrency and existing error tuples

`fetch_games` uses `/xmlapi2/thing` with comma-separated IDs, `type=boardgame`, and `stats=1`. Split unique supplied values into batches of at most 20. Run at most two batches concurrently per invocation, retain request-batch order and provider item order within each batch, and retain existing `retry: false` and 10-second Req receive timeout. Use a 15-second task timeout with timed-out work terminated and represented as an error tuple rather than a caller exit. No tasks may outlive completion of the operation. HTTP status, transport, parser, and task-timeout failures remain errors at this adapter boundary.

Collect each completed ordered batch after the preceding batch instead of reverse accumulation. The result is all-or-error across detail batches: one failed batch returns an error rather than introducing a partial-success envelope. This intentionally discards successful batch attrs on that invocation; local listing then applies its existing fallback, while Hot fetching and provider listing propagate the error to the controller. Successful batches that merely omit an item retain all available attrs and let the caller fall back only for the omitted identity.

### Merge optional local association without selecting provider membership from the database

`list_by_provider` takes the selected provider attrs, queries matching local rows by their BGG IDs, and joins local fields without changing selected membership or order. Restrict this join to `Application.fetch_env!(:d20, :visible_game_stages)` so an entry never advertises a local route hidden by the same policy. Visible matches contribute stage and slug regardless of enabled state or engine presence. An unmatched or hidden local match contributes null stage and a numeric route slug derived from the selected BGG ID; the game remains in Games with an internal detail address. A numeric detail after an exact slug miss is provider-only even when a hidden or visible local row has the same BGG ID under another slug. An empty database or an empty visible-stage configuration does not suppress provider discovery, and discovery never inserts or updates local rows. The local lookup is named entries_by_bgg_id and each matched row is named entry; these names describe the existing persisted records without introducing a new struct.

Each entry remains exactly `%{id: positive_bgg_id, metadata: Metadata.t(), stage: stage_or_nil, slug: route_slug}`. `route_slug` is always a string: the selected visible local slug or `Integer.to_string(id)`, computed in the context. Identity remains outside the embedded presentation schema, and local `Game.id` remains an internal TypeID for sessions, details, and local ordering. Invalid or empty metadata never changes the selected BGG identity. A slug means an internal detail address and does not establish a local record, implemented engine, or launch permission.

### Compose independent home collections and make discovery failure explicit

The controller calls `list_playable` and `list_by_provider` directly. It removes the old exclusion expression and now-unused Ecto import. The same BGG game may appear once in each section when independently selected. Both arrays retain numeric BGG `id`, nullable `stage`, non-null route `slug`, and `game` metadata. The client does not reshuffle, filter, deduplicate across sections, or fetch more games during carousel motion. Each section owns its canonical accessible link; section-specific label IDs prevent overlap from colliding.

Hot request, credential, or Hot parsing failure means no source membership is known. `list_by_provider` returns that error; the controller records a provider-discovery warning and renders `games: []`, while Playable retains its locally selected entries and metadata fallback. A detail-operation error also returns through list_by_provider and renders empty Games with the existing controller warning. Successful responses with missing or invalid individual metadata retain those selected entries. Every card links internally to `/games/${entry.slug}`. Use the existing uniform `use:inertia` navigation pattern; remove `fromAction`, conditional attachments, and frontend local-versus-provider URL selection. Keep ordinary anchor semantics and accessible canonical-link ownership. Credentials must not appear in warnings or props.

### Resolve detail identity in the Games context

Exact persisted slug lookup runs first, even when the slug consists entirely of digits. A matched local record keeps its TypeID, stored slug, visibility policy, launch predicate, metadata fallback, and existing Session resolution. A hidden local slug is terminal under current policy and cannot fall through into a provider-only page; the existing matching-Session exception remains intact.

Only a missing exact slug enters provider resolution. Pass the original string directly to `BoardGameGeek.fetch_game(slug)` without regex matching or integer parsing in the context or either provider fetching function. Request encoding remains owned by Req query params. A successful single parsed provider record establishes the resulting identity; normalize its returned BGG ID to the decimal route string. Invalid input is handled through the provider response/error instead of an application-side route syntax rejection. Inline the fetch and Metadata construction in the local-miss branch; remove fetch_provider_detail rather than retaining a single-use helper.

Do not add another local lookup by BGG ID after the exact slug miss. Thus `/games/183006` remains provider-only when the local Qwinto row uses slug `qwinto`, while normal catalog links still use `/games/qwinto` because listing already joined the visible row. A same-BGG hidden local row under another slug contributes no local identity, stage, or launch capability. No canonical redirect to the stored slug is added.

Return `{:ok, %{entry: Game.t() | nil, slug: String.t(), metadata: Metadata.t()}}` from `fetch_by_slug/1`. The context-resolved route slug accompanies the optional persisted entry without constructing a fake `%Game{}` or a new domain struct. Keep persisted-only `get_by_slug` and id-based lookup boundaries for Session creation and modules. The controller handles HTTP and props; it does not perform Repo lookup, provider parsing, or provider requests.

### Render provider details without local runtime identity

Provider-only detail props are `id: null`, `slug: decimal_bgg_id`, `stage: null`, `can_launch_game: false`, `game: metadata`, `schema: null`, and `session: null`. Keep local detail `id` as its TypeID string, distinct from catalog numeric BGG `id`; do not overload the detail ID with BGG identity. Update detail props typing to accept null identity/stage. Metadata construction uses the existing embedded schema, and successful absent optional fields keep current preview/description/label fallbacks.

The existing detail page already omits LaunchForm when launch is false and schema is null. Preserve that behavior and the metadata layout; design no substitute button, disabled Play, or placeholder. Provider-only `?session=` cannot attach any local Session: use the existing Session-not-found error redirect to the bare internal numeric route. Session creation remains persisted-slug-only and never invokes provider fallback, so a provider-only POST returns the existing unknown-game 404 without creating a process or record.

Provider omission, configuration, HTTP, transport, parsing, or invalid Metadata failures do not prove that an unregistered game exists. Preserve the source error at the context boundary and the current controller 404 mapping; do not render a successful empty provider-only detail after a failed operation. Existing local details continue to survive enrichment failure through Metadata.empty and current visibility rules. Provider-only pages require no Hot membership and may be opened directly.

## Provider Evidence

[BGG XML API2](https://boardgamegeek.com/wiki/page/BGG_XML_API2), checked 2026-09-08, documents Hot, comma-separated Thing IDs with a maximum of 20, and throttling that may return 500/503. It describes no Hot limit, pagination, fixed response-size guarantee, or random endpoint. Random Hot sampling is application behavior. The documentation's approximate five-second pacing advice does not establish that two concurrent requests are globally safe. No authenticated live request or credential read is needed to verify this implementation with transport fixtures.

## Risks / Trade-offs

- BGG Hot is a changing interest-based pool, so random selection is not a uniform sample of every BGG game. Verify subset membership and limits without asserting that repeated calls must differ.
- Two concurrent detail requests are bounded per invocation, not globally. Concurrent home requests can multiply load and trigger provider throttling. Preserve errors and fallback; a cache/shared rate limiter remains outside this approved scope.
- All-or-error detail batches may discard some successful metadata. Propagating the error keeps the return contract small and avoids a new partial-result protocol.
- Hot discovery adds one request before detail loading. Bound task lifetime and preserve the successful page response when discovery fails.
- Changing slug from optional local identity to a required route identifier affects catalog, detail, and frontend props. Verify all seven capability deltas and nearby tests together, including empty persistence and empty visibility.
- Exact numeric local slugs share the namespace with BGG fallback IDs and may shadow them. Preserve exact-slug precedence and visibility explicitly; this change does not add a new slug restriction or collision migration.
- Numeric fallback deliberately does not recover a local association by BGG ID. Normal catalog links prefer the joined local slug; direct numeric routes remain metadata-only. Test both addresses to keep launch capabilities distinct.
- Cross-section overlap requires unique label IDs and one accessible link per section. Verify the existing section prefixes and uniform internal Inertia navigation; no carousel redesign is needed.
- Prior broad validation has known failures in unchanged schema, Koala, page-layout, and player-count tests. Record new check outcomes independently and do not claim earlier results validate provider discovery.

## Migration Plan

Implementation and focused verification are complete and the owning change is synchronized and archived. The user subsequently authorized committing all related work and transferring the unpublished branch to local master. Include the verified implementation and reconciled artifacts in one semantic commit, validate the candidate and integrated target, and preserve unrelated state. Record integration evidence in issue #272.

Update context resolution, controller props, frontend links/types, and tests together. No schema, data, dependency, runtime configuration, or public Session protocol migration is required. Validate backend resolution/visibility/Session boundaries and frontend internal navigation/no-Play behavior with native focused commands, then reconcile the delivery artifacts and run the required lifecycle. Rollback of the future routing implementation restores its code and props changes without touching persisted data.

The active `manage-persisted-game-catalog` change, owned by [issue #223](https://github.com/ravecat/d20/issues/223), also modifies game-detail from registry terminology to persisted slugs and has not synchronized that delta. This #272 continuation builds on the existing persisted implementation. Its overlapping game-detail delta is reconciled to this change's combined local/provider contract and requirement name. This change synchronizes the registered-to-local-and-provider requirement rename first; the older change retains only matching modifications, so its later archival cannot restore local-only detail behavior. The older change's outstanding Infra and rollback tasks remain open.

## Open Questions

- No blocking questions remain. The user confirmed that the string route identifier resolves an exact local slug first, then passes the original string to the provider without client-side ID validation in either provider function. No intermediate local lookup by BGG ID is added.
- Deferred by the user: What replaces Play for games without local launch capability? This is outside current scope and does not block metadata-only pages with no replacement control.
