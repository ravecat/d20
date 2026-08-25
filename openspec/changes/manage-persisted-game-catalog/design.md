## Context

`config/config.exs` currently declares nineteen games under `D20.Games.Registry`. The nested `Registry.Entry` embedded changeset validates `slug`, `bgg_id`, optional `engine`, and optional `status`; `D20.Games` enriches those entries synchronously from BoardGameGeek. The configured slug then leaks into every operational seam: catalog/detail routes, `D20.Sessions` and `D20.Sessions.Server` state, `D20.Accounts.Scope`, SessionChannel authorization, Workspace descriptors, module controller routes, signed module claims, and iframe subdomains.

This makes a provider-facing name key act as the local aggregate identity. It also makes routine binding and launch-control changes deployment work. The new model must move those concerns to PostgreSQL without storing BGG presentation data, loading code dynamically, or changing live Session lifecycle semantics.

The repository already has Ecto/PostgreSQL, Phoenix 1.8, LiveView 1.1, TypeID-backed persisted account identities, a shared LiveSocket, Tailwind CSS 4, daisyUI 5, Heroicons, Vite, Bun, account sessions, and `D20.Release` release operations. Backpex 0.20 supports Phoenix `< 1.9`, LiveView `~> 1.0`, Tailwind 4, daisyUI 5, and Ecto; its Ecto adapter delegates primary-key casting to the configured schema, so the game resource can use the same string-backed TypeID convention without a parallel frontend application.

The active `refine-borderless-app-shell` change contains unfinished work that still describes `D20.Games.Registry` as a developer-spec allow-list. Issue #223 remains an independent delivery outcome, but implementation must remove that code dependency and keep static specification identifiers distinct from operational game identity before either change is finalized.

## Goals / Non-Goals

**Goals:**

- Make a persisted `game` TypeID the only operational identity of a catalog game.
- Preserve all nineteen current catalog records and their current stage, BGG, and engine bindings.
- Enforce record invariants in both Ecto changesets and PostgreSQL.
- Let administrators edit only `bgg_id`, `stage`, `enabled`, and `engine` through an authenticated Backpex resource.
- Keep runtime BGG metadata non-authoritative and non-persistent, and defer public game slugs entirely.
- Apply catalog edits only to future metadata reads and future Session creation while leaving existing Session processes intact.
- Update all affected browser, module, Workspace, token, and AsyncAPI contracts coherently.

**Non-Goals:**

- Persisting BGG names, descriptions, images, public slugs, aliases, or metadata caches.
- Adding another metadata provider, provider abstraction, dynamic engine loading, per-game iframe policy, audit fields, disable reasons, or rollout reasons.
- Creating or deleting games through Backpex in this change.
- Administering users or allowing an account to grant itself administrator access over HTTP.
- Terminating, mutating, revalidating, or adding channel/network checks to existing Sessions after a game edit.
- Implementing changes in separate iframe game repositories; their contract/deployment coordination is an explicit cutover prerequisite.
- Displaying BGG presentation metadata in Backpex. The accepted scope permits read-only metadata, but omitting synchronous provider calls keeps this resource reliable and minimal.

## Decisions

### 1. Replace Registry with a persisted Game schema and keep metadata separate

`D20.Games.Game` will become the persisted `games` schema and local game entity. The current embedded presentation schema will move to `D20.Games.Metadata`. `D20.Games` remains the deep context interface for id lookup, ordered catalog enrichment, changesets/updates, and the launch predicate. `D20.Games.Registry` and its application configuration will be removed rather than retained as a compatibility proxy.

The table disables Ecto's default bigint key and defines a string-backed TypeID primary key plus these fields:

- `id`: string-backed `TypeID`, required, primary key, generated with prefix `game`.
- `bgg_id`: integer, required, positive, unique.
- `stage`: required string-backed `Ecto.Enum` with `planned`, `in_development`, and `released`.
- `enabled`: required boolean with database and schema default `true`.
- `engine`: nullable integer-backed `Ecto.Enum` whose loaded values are engine modules.
- normal UTC timestamps.

The schema declares `@primary_key {:id, TypeID, autogenerate: true, prefix: "game"}` and owns `@type id :: TypeID.t()`. Context and runtime specifications reference `D20.Games.Game.id()` directly rather than introducing proxy id types. The migration adds a named database check for the canonical `game_[0-7][0123456789abcdefghjkmnpqrstvwxyz]{25}` representation so direct writes cannot bypass the prefix contract.

No slug or BGG presentation column is added. Separating `Game` from `Metadata` avoids an Ecto schema that pretends externally fetched data is persisted and gives callers an explicit distinction between stable local facts and transient presentation.

Keeping the existing `Registry` name for database queries was rejected because it would retain the wrong mental model and a shallow compatibility seam. Adding a generic external-identifier table was rejected because one BGG binding is the complete current requirement.

### 2. Use permanent integer engine mappings and database checks

The schema owns this exact mapping and it is never reordered, reused, or renumbered:

```elixir
field :engine, Ecto.Enum,
  values: [
    {D20.Fliptown.Game, 1},
    {D20.KoalaRescueClub.Game, 2},
    {D20.NextStationLondon.Game, 3},
    {D20.Qwinto.Game, 4}
  ]
```

A module rename changes only the atom at its existing numeric value. `D20.Games.Game.engines/0` exposes the deployed engine modules directly from `Ecto.Enum.values/2`; it does not produce UI labels. Backpex uses those module atoms directly as selector options without duplicating the module list or owning a second presentation-label mapping. Loaded non-nil values are passed through `D20.Game.ensure_engine/1` before a Session starts.

The migration adds named checks equivalent to:

- `bgg_id > 0`
- `stage IN ('planned', 'in_development', 'released')`
- `engine IS NULL OR engine IN (1, 2, 3, 4)`
- `stage = 'planned' OR engine IS NOT NULL`

It also creates the unique BGG index. Ecto validation and `check_constraint`/`unique_constraint` surface useful admin errors, while PostgreSQL remains authoritative under concurrent or non-Backpex writes. Planned rows may still have an engine, preserving Fliptown without implying production release.

Persisting module names as strings was rejected because renames would become data migrations and arbitrary atoms would be unsafe. A PostgreSQL enum was rejected because Ecto.Enum plus named checks is simpler to evolve while retaining explicit integer engine compatibility.

### 3. Backfill generated game TypeIDs for every current entry

One reversible migration creates and backfills the complete table in current `config/config.exs` order. It generates a distinct `game` TypeID for each row inside the target database instead of hardcoding identifiers shared by every environment:

| BGG id | implementation stage | engine value |
| ---: | --- | ---: |
| 360471 | planned | null |
| 342200 | planned | null |
| 322703 | planned | null |
| 169654 | planned | null |
| 420087 | planned | null |
| 352418 | planned | 1 |
| 425873 | released | 2 |
| 50 | planned | null |
| 361850 | planned | null |
| 353545 | in_development | 3 |
| 245654 | planned | null |
| 183006 | released | 4 |
| 131260 | planned | null |
| 302280 | planned | null |
| 373106 | planned | null |
| 352454 | planned | null |
| 283864 | planned | null |
| 350736 | planned | null |
| 388329 | planned | null |

The migration generates the TypeIDs with strictly increasing millisecond timestamps in this table order so their K-sort order preserves the former registry order without treating a catalog ordinal as identity. Every row starts with `enabled = true`. Existing released/in-development launch behavior is therefore preserved, while planned rows remain non-launchable by stage. The admin resource has no create/delete routes; any later row receives a normally autogenerated `game` TypeID.

Generating ids from BGG ids was rejected because correcting `bgg_id` must not change identity. Hardcoding the same TypeIDs across environments was rejected because TypeIDs are entity identities generated in the owning database, not deployment-independent catalog constants. Persisting the former slug was rejected because it is provider-derived presentation under the agreed model.

### 4. Expose no public game slug in this change

`D20.Games` returns catalog entries as `{id, stage, metadata}` and detail lookup as `{game, metadata}`. Runtime BGG names remain display data only and are not normalized into a public route field. Catalog and detail Inertia props therefore contain no game slug, and the frontend navigates directly to `/games/:id`.

Persisting the former slug was rejected because it would add a second identity and requires an explicit rename, alias, and redirect policy. Deriving a transient slug was rejected because it adds URL variants without stable reverse lookup or outage behavior. Human-readable game URLs are deferred to a separate change.

### 5. Resolve public and module routes only by id

The router exposes:

- `GET /games/:game_id`
- `POST /games/:game_id/sessions`
- `OPTIONS /modules/:game_id`
- `POST /modules/:game_id`

Controllers pass the local id to the persisted lookup and rely on TypeID/Ecto primary-key casting. A well-formed `game_...` id absent from persistence returns the existing not-found response. Malformed TypeIDs and valid TypeIDs with another entity prefix fail casting with `Ecto.Query.CastError`, which Phoenix.Ecto maps to `400 Bad Request`. Catalog links, Session form submissions, success and validation redirects, and lobby cleanup navigation all target the same `/games/:id` detail path. Old slug-only routes and the interim `/games/:id/:slug` variant are absent with no compatibility lookup or canonical redirect.

A slug-only route was rejected because runtime BGG metadata cannot provide stable reverse lookup. A composite id-plus-slug route was rejected for now because the readable suffix provides no identity value and introduces canonicalization behavior that the current outcome does not need.

### 6. Make enabled an independent new-Session gate

`D20.Games.session_launch_available?/1` returns true exactly when:

- `enabled` is true, and
- stage is `released`, or stage is `in_development` while `:allow_launch_in_development` is true, and
- the record has a supported non-nil engine.

`planned` never launches, even if it has an engine. The detail controller uses this predicate to set `can_launch_game` and omits the engine-owned JSON Schema and Play form when false. Both `PageController.create_game_session/2` and the no-session branch of `ModuleController.create/2` call the same predicate before engine resolution or process creation and return their existing forbidden semantics.

The existing-session branch of `ModuleController` checks only that the supplied Session carries the requested game id. SessionChannel, ModuleSocket, WorkspaceChannel, Presence, and game channels add no enabled or stage check. This keeps a disabled game discoverable and existing sessions usable without a kill switch hidden in a catalog flag.

Conflating `enabled` with implementation stage was rejected because operators need to stop new sessions without changing catalog maturity. Enforcing only in the UI was rejected because direct HTTP requests must be safe.

### 7. Capture game id and engine in each Session process

`D20.Sessions.create/4` changes from `(slug, engine, owner_id, attrs)` to `(game_id, engine, owner_id, attrs)`. Its public state becomes `{Session.t(), game_id}` and Session-server state becomes `{game_id, engine, Session.t()}`. The engine module is still resolved and passed at creation, so a later database engine edit cannot alter the reducer or custom server of a running process.

`D20.Accounts.Scope.game` becomes `%{id: D20.Games.Game.id()}`. User and module SessionChannel joins compare the scoped TypeID with the id captured by the Session process. `D20.Sessions.create/4` relies on its persisted game lookup, while Scope mutation and Session server initialization trust the validated game and token boundaries instead of repeating local game-id guards. External routes rely on TypeID/Ecto primary-key casting and Phoenix.Ecto exception mapping, while token verification retains validation at its owning boundary. `D20.Sessions.list/1`, default/custom servers, Koala and Next Station custom callbacks, Workspace, and their tests carry the id without re-reading engine or launch policy.

Persisting Sessions was rejected because current Sessions are intentionally volatile OTP processes. Looking up the current engine on every command was rejected because it would mutate existing gameplay after an admin edit.

### 8. Use game id in Workspace, module claims, and module hosts

Workspace descriptors change from `{id, slug, phase, module, connection}` to `{id, game_id, phase, module, connection}` where `id` remains the Session UUID. Snapshot construction fetches the persisted game by `game_id` only to confirm it still exists and build framing data; it does not filter by `enabled` or stage. TypeScript consumes `gameId` after Inertia/JSON camelization and otherwise preserves authoritative replacement, monitoring, window, close, and iframe behavior.

`D20Web.Module.connection/3` and `D20.Module.Token` sign the full string `game_id` TypeID claim instead of `slug`. ModuleSocket validates the `game` prefix, puts that id in Scope, and includes it in the socket id. SessionChannel rejects a token whose game id does not match the Session's captured id. Module HTTP requests also match existing Sessions by id.

Because the canonical TypeID contains `_`, which is invalid in a DNS host label, `D20Web.Module.entry/2` derives the stable iframe host as `game-<typeid-suffix>.<shell-host>`. The suffix is the 26-character globally unique TypeID payload, so the host remains a one-to-one DNS-safe projection of the full persisted id. The function trusts the persisted game or Session boundary that supplied the id instead of repeating TypeID validation. `connection/3` follows the same internal contract; Session topic construction and token verification retain their owning validation. CORS, sandbox, endpoint, topic, actor, expiry, and token behavior remain unchanged. A BGG binding or presentation-name edit therefore cannot move a running iframe. The deployment must provide corresponding wildcard host/DNS routing and iframe clients must call `/modules/:game_id` with the full TypeID before cutover.

Keeping the BGG slug as the subdomain was rejected because a presentation rename would still change an operational address. Deriving the host from `engine` was rejected because engine edits must not redefine local game identity.

Static developer contract slugs remain document identifiers, not game identity. `D20Web.Plugs.AsyncApi` must stop calling the removed Registry; it may resolve only validated regular game-spec files while continuing to exclude the internal `workspace.yaml`. This also unblocks the pending developer-page work without introducing a slug lookup into `D20.Games`.

### 9. Add an update-only Backpex LiveResource in the existing asset/runtime stack

Add `{:backpex, "~> 0.20.0"}` plus Backpex PubSub and formatter configuration. Because D20 uses Bun/Vite rather than Backpex's default esbuild setup, `assets/package.json` adds `backpex` as a local `file:../deps/backpex` dependency and updates the Bun lock. The shared app entrypoint merges `BackpexHooks` with colocated hooks and wraps LiveSocket params with `backpexParams`. Tailwind adds the two Backpex `@source` paths. Existing Tailwind 4, daisyUI 5, and Heroicons remain the only styling/icon systems; no second LiveSocket, CSS pipeline, or JS application is added.

One `live_session :dashboard` wraps the protected `/dashboard` scope so every administrative LiveView runs the `D20Web.Auth` `:admin` on-mount hook before `Backpex.InitAssigns`. The nested scope applies browser authentication and the `D20Web.Auth.require_administrator/2` function Plug directly to every route, including `backpex_routes()`. `live_resources "", D20Web.Admin.GameLive, only: [:index, :show, :edit]` mounts the Backpex index directly at `/dashboard` and show/edit actions at `/dashboard/:backpex_id/show` and `/dashboard/:backpex_id/edit`, so no proxy controller or redirect owns the dashboard root. Omitting new/delete routes and denying other resource actions defensively through `can?/3` keep the resource update-only, while the supported actions separately consult `D20.Games.Policy/:manage_games`.

The resource uses the persisted schema and update changeset. Fields are:

- read-only textual `id` showing the full `game_...` TypeID
- inline-editable positive `bgg_id`
- inline-editable `stage` Select from `Ecto.Enum.values/2`
- inline-editable `enabled` Boolean
- inline-editable nullable `engine` Select from `D20.Games.Game.engines/0`, using the module atoms directly as options with a `None` prompt

Backpex index editing persists each cell independently through the same update changeset and `:edit` capability check as the dedicated edit view. The edit route remains available for coordinated multi-field changes, while invalid inline values retain the persisted record and surface the field's invalid state.

A small Backpex app-shell layout reuses the existing root document, theme tokens, daisyUI, Heroicons, flash, home link, and logout link. It does not synchronously fetch BGG metadata. Running the generic installer without review was rejected because it assumes the default Phoenix asset layout and npm; integration is applied manually to the repository's established Vite/Bun files.

### 10. Authorize admin HTTP and LiveView lifecycle with persisted account state

A separate migration adds `users.role varchar NOT NULL DEFAULT 'user'` with a named domain constraint allowing only `user` and `admin`. The User schema loads it as a string-backed `Ecto.Enum` with values `[:user, :admin]` and default `:user`. Registration, settings, and provider changesets never cast `role`; there is no user Backpex resource.

The existing browser pipeline loads `current_user`, and `require_authenticated_user` remains responsible only for authentication and login UX. Every successful Inertia-owned login marks its redirect for a full-page browser visit, regardless of the safe return path. This keeps authentication unaware of route topology while allowing the flow to return to non-Inertia destinations such as `/dashboard` without parsing their HTML as an Inertia response. Every `/dashboard` route, including Backpex preferences, then passes directly through the `D20Web.Auth.require_administrator/2` function Plug, which accepts only a persisted `%D20.Accounts.User{role: :admin}` and returns forbidden otherwise.

The outer `live_session :dashboard` invokes `D20Web.Auth.on_mount/4` with the `:admin` discriminator before `Backpex.InitAssigns`. The hook re-resolves the persisted user from the session token and checks the same role, so direct WebSocket mounts, reconnects, and live navigation cannot rely only on the initial Plug check. This is one administration-area gate rather than a catalog capability check. Backpex `GameLive.can?/3` separately delegates index, show, and edit authorization to `D20.Games.Policy/:manage_games`; future administrative resources own their resource-specific policies without adding those actions to the route pipeline or shared LiveView hook.

Initial access is granted by an operator with trusted direct access to the target environment's database. The operator updates one already registered account from `user` to `admin`, verifies the affected account, and uses the same database boundary to revoke the role when needed. Production and development databases are managed independently. No application context function, release command, environment variable, browser endpoint, ordinary user changeset, registration parameter, or Backpex field can mutate the role.

A boolean administrator flag was rejected because each additional mutually exclusive account role would otherwise encourage another authorization flag. Reusing each resource capability policy as the `/dashboard` route gate was rejected because the administration area may contain many resources and actions; the shared gate checks only whether the persisted account is an administrator. A generic configurable `require_role` helper was rejected because the application currently has one administrative area and no second route-level role requirement. Normalized role, user-role, and permission tables remain deferred until D20 has evidence that accounts need multiple simultaneous roles or independently assignable capabilities. BasicAuth was rejected because D20 already has account sessions and needs revocable per-user authorization. A second authorization dependency was rejected because Bodyguard 2.4.3 is already deployed and remains appropriate for resource capability policies. Application or release bootstrap helpers were rejected because trusted database access already owns this rare operation; an email-based privileged helper would add a second mutation surface and deployment-specific configuration without creating a stronger trust boundary.

### 11. Update public contracts and validate at their owning seams

`priv/specs/workspace.yaml` replaces descriptor `slug` with string `game_id` constrained to the canonical `game` TypeID pattern and keeps Session `id`, phase, module, connection, and close behavior. Module token and controller tests assert full TypeID `game_id` claims, wrong-prefix rejection, and id mismatch rejection. Catalog/detail Inertia props and TypeScript expose stable local game identity as string `id`, replace `status` with `stage`, omit public game slugs, and use TypeID-only navigation. Session and Workspace descriptors retain string `gameId` because their `id` remains the Session UUID.

Tests cover the `game` TypeID schema and database constraint, nineteen-row backfill bindings and TypeID uniqueness/order, context ordering/enrichment/fallback, TypeID-only navigation and route rejection, both disabled creation endpoints, existing disabled/edited Sessions, captured engine behavior, Session/Scope/channel authorization, Workspace JSON and AsyncAPI, DNS-safe module subdomain/full claim/CORS, Backpex textual id display and update validation, the shared administrator-role gate across HTTP and LiveView, the separate Bodyguard catalog resource policy, forged-role non-escalation, and frontend navigation/launch hiding. Browser validation covers anonymous, non-admin, and admin `/dashboard` access; game edits and validation errors; disabled detail UI; TypeID routes; and desktop/narrow Backpex rendering.

Unit tests alone were rejected because this change crosses database, HTTP, LiveView, channel, iframe, and browser asset seams.

## Risks / Trade-offs

- [Backpex 0.x interfaces can change] -> Pin to the compatible `~> 0.20.0` line, use standard fields/routes only, and cover the resource through LiveView and browser tests.
- [A migrated binding or enum number is wrong] -> Assert all nineteen BGG/stage/engine bindings after migration plus unique valid `game` TypeIDs and preserved K-sort order.
- [Draft bigint migration already ran locally] -> Because this change is uncommitted and undeployed, roll back only the draft games migration and rerun it after revision; never reset or drop unrelated development data.
- [Human-readable URLs are deferred] -> Keep `/games/:id` as the only public game route until a separate slug persistence, alias, and redirect policy is approved.
- [Operator changes BGG or engine accidentally] -> Database constraints reject malformed combinations; stable id and captured Session engine limit the blast radius. Audit/reason workflows remain intentionally out of scope.
- [An engine changes while Sessions are running] -> Existing server tuples retain the old engine; only later `Sessions.create` calls receive the edited engine.
- [Disabled games disappear from a running Workspace] -> Workspace ignores launch flags and resolves by stable id, so existing sessions remain present.
- [New TypeID-derived iframe hosts do not resolve] -> Provision wildcard `game-<typeid-suffix>` routing and update standalone module consumers before the breaking application cutover.
- [Administration entry and catalog resource authorization are conflated] -> Require the persisted administrator role consistently at HTTP and LiveView boundaries, re-resolve it before Backpex initialization, and keep catalog action checks in `GameLive.can?/3`.
- [Old release cannot observe admin edits] -> Application rollback is possible but restores checked-in catalog behavior; export current rows before destructive schema rollback.
- [The pending developer-page change reintroduces Registry] -> Reconcile its unfinished registry-dependent task against static specification identifiers before archiving either change.

## Migration Plan

1. Add and test the additive `games` and string-backed `users.role` migrations, including generated `game` TypeID backfill, prefix/domain enforcement, and role-domain enforcement. If the undeployed draft bigint games migration ran locally, roll back that migration only before rerunning it.
2. Add the persisted schema/context and id-based runtime/web/contracts while the old release can still ignore the additive tables.
3. Integrate and test Backpex assets, routes, and authorization without adding an application or release role-assignment interface.
4. Provision wildcard `game-<typeid-suffix>` host routing and update external iframe module consumers to the full-TypeID module endpoint/claim contract.
5. Take a database backup, run migrations, deploy the coordinated application release, and smoke-test catalog/detail/module/session flows.
6. Assign `admin` to an already registered operator through trusted direct database access, verify the affected account, and then verify anonymous, ordinary-user, and admin access.
7. Verify that disabling a game blocks both new-session HTTP paths while a pre-existing Session remains connected, and verify that an engine edit affects only a newly created Session.

For an application rollback, deploy the prior code while leaving the additive tables in place; the prior release resumes its checked-in registry and ignores persisted edits. Before rolling migrations down, stop new-code traffic and export/backup `games` plus administrator assignments. The reversible down migrations then remove `games` and `users.role`; this is destructive and must not be the first rollback response.

## Open Questions

None.
