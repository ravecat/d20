## Context

Before the persisted-catalog refactor, `config/config.exs` declared nineteen games under `D20.Games.Registry`. Each entry had a stable operator-chosen slug plus `bgg_id`, optional `engine`, and optional `status`. The slug already named public game routes, standalone client repositories, local Traefik hosts, Cloudflare Pages projects, and production module domains.

The intermediate persisted implementation correctly moved operational bindings to PostgreSQL and introduced environment-local `game` TypeIDs, but it removed slug and projected TypeID into public routes and iframe hosts. Database resets now assign different hosts to the same game while existing local and production infrastructure still routes the stable slugs. The corrected model must preserve separate identities: TypeID for database and live Session authority, and required immutable slug for external game and deployment addressing. Neither identity may depend on runtime BoardGameGeek presentation metadata.

The repository already has Ecto/PostgreSQL, Phoenix 1.8, LiveView 1.1, TypeID-backed persisted account identities, a shared LiveSocket, Tailwind CSS 4, daisyUI 5, Heroicons, Vite, Bun, account sessions, and `D20.Release` release operations. Backpex 0.20 supports Phoenix `< 1.9`, LiveView `~> 1.0`, Tailwind 4, daisyUI 5, and Ecto; its Ecto adapter delegates primary-key casting to the configured schema, so the game resource can use the same string-backed TypeID convention without a parallel frontend application.

The active `refine-borderless-app-shell` change contains unfinished work that still describes `D20.Games.Registry` as a developer-spec allow-list. Issue #223 remains an independent delivery outcome, but implementation must remove that code dependency and keep static specification identifiers distinct from operational game identity before either change is finalized.

## Goals / Non-Goals

**Goals:**

- Keep a persisted environment-local `game` TypeID as database, Session, Workspace, module API, scope, and token identity.
- Persist a required unique DNS-safe slug as the stable external identity of every game, including planned games.
- Preserve all nineteen current catalog records, their former registry slugs, and their current stage, BGG, and engine bindings.
- Enforce record invariants in both Ecto changesets and PostgreSQL and prevent ordinary slug edits after insertion.
- Let administrators create games with explicit slug and BGG binding, then edit only `bgg_id`, `stage`, `enabled`, and `engine` through authenticated Backpex actions.
- Keep runtime BGG metadata non-authoritative and non-persistent; never regenerate slug from provider metadata.
- Apply mutable catalog edits only to future metadata reads and future Session creation while leaving existing Session processes intact.
- Restore slug-based public game URLs and iframe hosts while retaining TypeID-based live runtime and module connection contracts.

**Non-Goals:**

- Persisting BGG names, descriptions, images, slug aliases, slug history, redirects, or metadata caches.
- Deriving slug from BoardGameGeek, engine module names, TypeID, or current presentation title after creation.
- Adding another metadata provider, provider abstraction, dynamic engine loading, per-game iframe policy, audit fields, disable reasons, or rollout reasons.
- Deleting games through Backpex or renaming an existing slug through an ordinary admin edit.
- Administering users or allowing an account to grant itself administrator access over HTTP.
- Terminating, mutating, revalidating, or adding channel/network checks to existing Sessions after a game edit.
- Implementing changes in separate iframe game repositories; they already consume canonical slug hosts and remain outside this repository change.
- Making Infra query D20 for desired deployment state; the first cutover keeps the explicit canonical slug set and defers backend-driven reconciliation.
- Displaying BGG presentation metadata in Backpex. The accepted scope permits read-only metadata, but omitting synchronous provider calls keeps this resource reliable and minimal.

## Decisions

### 1. Persist internal TypeID and external slug as separate game facts

`D20.Games.Game` becomes the persisted `games` schema and local game entity. The current embedded presentation schema moves to `D20.Games.Metadata`. `D20.Games` remains the context interface for internal id lookup, external slug lookup, ordered catalog enrichment, create/update changesets, and launch policy. `D20.Games.Registry` and its application configuration are removed rather than retained as a compatibility proxy.

The table disables Ecto's default bigint key and defines:

- `id`: string-backed `TypeID`, required, primary key, generated with prefix `game` by the owning database.
- `slug`: string, required, unique, at most 63 characters, matching `^[a-z0-9]+(-[a-z0-9]+)*$`.
- `bgg_id`: integer, required, positive, unique.
- `stage`: required string-backed `Ecto.Enum` with `planned`, `in_development`, and `released`.
- `enabled`: required boolean with database and schema default `true`.
- `engine`: nullable integer-backed `Ecto.Enum` whose loaded values are engine modules.
- normal UTC timestamps.

The schema declares `@primary_key {:id, TypeID, autogenerate: true, prefix: "game"}` and owns `@type id :: TypeID.t()`. Context and runtime specifications reference `D20.Games.Game.id()` directly. The migration adds named database checks for canonical TypeID and DNS-safe slug representations plus unique indexes for slug and BGG binding.

`id` and `slug` intentionally have different authority. TypeID owns database relationships, Session state, Workspace descriptors, `/modules/:game_id`, module socket scope, and signed claims. Slug owns stable public game URLs and iframe origins across environments. A TypeID changes when a database is rebuilt; a slug is assigned by the D20 administrator before dependent repositories or infrastructure exist and remains unchanged through BGG edits, title changes, engine edits, and database-environment differences.

The create changeset accepts and requires slug. The ordinary update changeset does not cast slug, and Backpex renders it read-only outside the new form. A slug rename is therefore an explicit coordinated data and infrastructure migration, not routine catalog editing. PostgreSQL enforces format and uniqueness, while application/admin boundaries enforce ordinary immutability.

Separating `Game` from `Metadata` avoids pretending externally fetched data is persisted. Calling slug a presentation field was rejected because current repositories, Pages projects, DNS, and local routing already consume it as an operational identifier. A separate deployment-key column was rejected because it would duplicate the same stable identity without a second current use case.

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

- `slug` matches the canonical lowercase DNS-label form and is at most 63 characters
- `bgg_id > 0`
- `stage IN ('planned', 'in_development', 'released')`
- `engine IS NULL OR engine IN (1, 2, 3, 4)`
- `stage = 'planned' OR engine IS NOT NULL`

It also creates unique slug and BGG indexes. Ecto validation and `check_constraint`/`unique_constraint` surface useful admin errors, while PostgreSQL remains authoritative under concurrent or non-Backpex writes. Planned rows may still have an engine, preserving Fliptown without implying production release.

Persisting module names as strings was rejected because renames would become data migrations and arbitrary atoms would be unsafe. A PostgreSQL enum was rejected because Ecto.Enum plus named checks is simpler to evolve while retaining explicit integer engine compatibility.

### 3. Backfill canonical slugs and generated TypeIDs for every current entry

One reversible migration creates and backfills the complete table in former `config/config.exs` order. Each row keeps its exact former registry slug while receiving a distinct `game` TypeID inside the target database:

| slug | BGG id | stage | engine |
| --- | ---: | --- | ---: |
| `aquamarine` | 360471 | planned | null |
| `confusing-lands` | 342200 | planned | null |
| `death-valley` | 322703 | planned | null |
| `deep-sea-adventure` | 169654 | planned | null |
| `flip-7` | 420087 | planned | null |
| `fliptown` | 352418 | planned | 1 |
| `koala-rescue-club` | 425873 | released | 2 |
| `lost-cities` | 50 | planned | null |
| `nimalia` | 361850 | planned | null |
| `next-station-london` | 353545 | in_development | 3 |
| `railroad-ink` | 245654 | planned | null |
| `qwinto` | 183006 | released | 4 |
| `qwixx` | 131260 | planned | null |
| `shifting-stones` | 302280 | planned | null |
| `sky-team` | 373106 | planned | null |
| `trailblazers` | 352454 | planned | null |
| `trails-of-tucana` | 283864 | planned | null |
| `voyages` | 350736 | planned | null |
| `waypoints` | 388329 | planned | null |

The migration generates TypeIDs with strictly increasing millisecond timestamps in this table order so their K-sort order preserves former catalog order without turning that order into identity. Every row starts with `enabled = true`. Existing released/in-development launch behavior is preserved, while planned rows remain non-launchable by stage. A later Backpex-created row requires an explicit slug and receives a normally autogenerated TypeID.

Generating TypeIDs from BGG ids was rejected because correcting `bgg_id` must not change internal identity. Hardcoding the same TypeIDs across environments was rejected because they belong to each database. Generating slug from BGG metadata during migration or runtime was rejected because the stable values already exist and external names are mutable. The explicit slug backfill is the cross-environment deployment contract.

### 4. Expose persisted slug as the stable external game identity

`D20.Games` returns catalog entries as `{id, slug, stage, metadata}` and supports separate lookups by internal id and external slug. Runtime BGG names remain display data and are never normalized into slug. Catalog and detail Inertia props expose both values where needed: slug drives browser navigation, while TypeID associates page and Session data.

Slug is immutable rather than supported through alias history in this change. Therefore one canonical route `/games/:slug` is sufficient, and unknown slugs return not found. Future rename requirements must introduce an explicit alias/redirect policy and coordinated repository, DNS, and Pages migration rather than silently changing this field.

Using the TypeID in public URLs was rejected because it is environment-local and changes after database reconstruction. Deriving a transient slug was rejected because it would not provide reverse lookup or infrastructure authority during metadata outages.

### 5. Resolve browser routes by slug and module APIs by TypeID

The router exposes:

- `GET /games/:slug`
- `POST /games/:slug/sessions`
- `OPTIONS /modules/:game_id`
- `POST /modules/:game_id`

Browser controllers resolve the required persisted slug, then use the loaded row's TypeID for launch policy, Session creation, matching Session queries, and runtime state. Unknown or non-canonical slugs return not found. Catalog links, Session form submissions, success and validation redirects, and lobby cleanup navigation all target the same `/games/:slug` detail path.

Standalone iframe clients continue calling `/modules/:game_id` using the TypeID delivered by module bootstrap. Module controllers retain TypeID/Ecto casting, token claims retain `game_id`, and SessionChannel compares that TypeID to the Session's captured id. This prevents a display/deployment address from replacing authoritative live Session identity.

A composite id-plus-slug route was rejected because required immutable slug already provides stable reverse lookup. Returning module APIs and tokens to slug was rejected because the persisted TypeID now correctly owns runtime authorization and Session relationships.

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

### 8. Use TypeID for Workspace authority and persisted slug for module origins

Workspace descriptors change from the former slug-authoritative shape to `{id, game_id, phase, module, connection}` where `id` remains the Session UUID. Snapshot construction fetches the persisted game by captured `game_id` both to confirm it still exists and to obtain immutable slug for framing; it does not filter an existing Session by `enabled` or stage. TypeScript consumes `gameId` after JSON camelization and otherwise preserves authoritative replacement, monitoring, window, close, and iframe behavior.

`D20Web.Module.connection/3` and `D20.Module.Token` sign the full string `game_id` TypeID claim. ModuleSocket validates the `game` prefix, puts that id in Scope, and includes it in the socket id. SessionChannel rejects a token whose game id does not match the Session's captured id. Module HTTP requests also match existing Sessions by id.

`D20Web.Module.entry/2` receives or resolves the persisted game and derives the iframe host as `<game.slug>.<shell-host>`. The same slug feeds `embed_url` and `allowed_origins`; sandbox policy remains shared configuration. CORS, endpoint, topic, actor, expiry, token, and `/modules/:game_id` behavior remain unchanged. BGG, title, stage, enabled, and engine edits cannot move an iframe because ordinary updates cannot change slug.

The canonical slugs already name the standalone repositories, local Traefik routers, Cloudflare Pages projects, and production domains. The immediate Infra cutover therefore removes exact `game-<typeid-suffix>` Pages aliases and retains its explicit slug set. Making Terraform query D20 directly is deferred because it requires a versioned authenticated registry contract, failure-closed reconciliation, deletion protection, and bootstrap handling.

Deriving the host from TypeID was rejected because IDs differ by environment. Deriving it from engine was rejected because engine edits must not redefine deployment identity. Treating slug as BGG presentation was rejected because it is assigned by D20 and remains independent of provider names.

Static developer contract slugs remain document identifiers rather than catalog lookup authority. `D20Web.Plugs.AsyncApi` stops calling the removed Registry and resolves only validated regular game-spec files while continuing to exclude internal `workspace.yaml`.

### 9. Add a create-and-update Backpex LiveResource in the existing asset/runtime stack

Add `{:backpex, "~> 0.20.0"}` plus Backpex PubSub and formatter configuration. Because D20 uses Bun/Vite rather than Backpex's default esbuild setup, `assets/package.json` adds `backpex` as a local `file:../deps/backpex` dependency and updates the Bun lock. The shared app entrypoint merges `BackpexHooks` with colocated hooks and wraps LiveSocket params with `backpexParams`. Tailwind adds the two Backpex `@source` paths. Existing Tailwind 4, daisyUI 5, and Heroicons remain the only styling/icon systems; no second LiveSocket, CSS pipeline, or JS application is added.

One `live_session :dashboard` wraps the protected `/dashboard` scope so every administrative LiveView runs the `D20Web.Auth` `:admin` on-mount hook before `Backpex.InitAssigns`. The nested scope applies browser authentication and `D20Web.Auth.require_administrator/2` directly to every route, including `backpex_routes()`. `live_resources "", D20Web.Admin.GameLive, only: [:index, :show, :new, :edit]` mounts the Backpex index directly at `/dashboard` and exposes creation plus show/edit actions without a proxy controller. Delete remains unavailable. `can?/3` authorizes `:new` and `:create` alongside index/show/edit through `D20.Games.Policy/:manage_games` and denies unsupported actions.

The resource uses a create changeset for insertion and the restricted update changeset afterward. Fields are:

- read-only textual `id` showing the generated full `game_...` TypeID after insertion
- required `slug`, editable only on the new form and read-only on index/show/edit
- positive `bgg_id`, required on create and inline-editable afterward
- `stage` Select from `Ecto.Enum.values/2`, defaulting to `planned` and inline-editable afterward
- `enabled` Boolean, defaulting to true and inline-editable afterward
- nullable `engine` Select from `D20.Games.Game.engines/0`, using module atoms directly with a `None` prompt

Creation validates the complete record and lets Ecto generate TypeID. Backpex index editing persists each mutable cell independently through the update changeset and `:edit` capability check. The edit route remains available for coordinated mutable-field changes, while invalid values retain the persisted record. No normal admin action can rename slug or delete the game.

A small Backpex app-shell layout reuses the existing root document, theme tokens, daisyUI, Heroicons, flash, home link, and logout link. It does not synchronously fetch BGG metadata. Running the generic installer without review was rejected because it assumes the default Phoenix asset layout and npm; integration is applied manually to the repository's established Vite/Bun files.

### 10. Authorize admin HTTP and LiveView lifecycle with persisted account state

A separate migration adds `users.role varchar NOT NULL DEFAULT 'user'` with a named domain constraint allowing only `user` and `admin`. The User schema loads it as a string-backed `Ecto.Enum` with values `[:user, :admin]` and default `:user`. Registration, settings, and provider changesets never cast `role`; there is no user Backpex resource.

The existing browser pipeline loads `current_user`, and `require_authenticated_user` remains responsible only for authentication and login UX. Every successful Inertia-owned login marks its redirect for a full-page browser visit, regardless of the safe return path. This keeps authentication unaware of route topology while allowing the flow to return to non-Inertia destinations such as `/dashboard` without parsing their HTML as an Inertia response. Every `/dashboard` route, including Backpex preferences, then passes directly through the `D20Web.Auth.require_administrator/2` function Plug, which accepts only a persisted `%D20.Accounts.User{role: :admin}` and returns forbidden otherwise.

The outer `live_session :dashboard` invokes `D20Web.Auth.on_mount/4` with the `:admin` discriminator before `Backpex.InitAssigns`. The hook re-resolves the persisted user from the session token and checks the same role, so direct WebSocket mounts, reconnects, and live navigation cannot rely only on the initial Plug check. This is one administration-area gate rather than a catalog capability check. Backpex `GameLive.can?/3` separately delegates new, create, index, show, and edit authorization to `D20.Games.Policy/:manage_games`; future administrative resources own their resource-specific policies without adding those actions to the route pipeline or shared LiveView hook.

Initial access is granted by an operator with trusted direct access to the target environment's database. The operator updates one already registered account from `user` to `admin`, verifies the affected account, and uses the same database boundary to revoke the role when needed. Production and development databases are managed independently. No application context function, release command, environment variable, browser endpoint, ordinary user changeset, registration parameter, or Backpex field can mutate the role.

A boolean administrator flag was rejected because each additional mutually exclusive account role would otherwise encourage another authorization flag. Reusing each resource capability policy as the `/dashboard` route gate was rejected because the administration area may contain many resources and actions; the shared gate checks only whether the persisted account is an administrator. A generic configurable `require_role` helper was rejected because the application currently has one administrative area and no second route-level role requirement. Normalized role, user-role, and permission tables remain deferred until D20 has evidence that accounts need multiple simultaneous roles or independently assignable capabilities. BasicAuth was rejected because D20 already has account sessions and needs revocable per-user authorization. A second authorization dependency was rejected because Bodyguard 2.4.3 is already deployed and remains appropriate for resource capability policies. Application or release bootstrap helpers were rejected because trusted database access already owns this rare operation; an email-based privileged helper would add a second mutation surface and deployment-specific configuration without creating a stronger trust boundary.

### 11. Update public contracts and validate at their owning seams

`priv/specs/workspace.yaml` keeps string `game_id` constrained to the canonical `game` TypeID pattern and preserves Session `id`, phase, module, connection, and close behavior. Module token and controller tests retain full TypeID claims, wrong-prefix rejection, and id mismatch rejection. Catalog/detail Inertia props and TypeScript expose both string `id` and required `slug`, replace `status` with `stage`, and navigate by slug. Workspace descriptors retain string `gameId` because their `id` remains the Session UUID; module framing inside each descriptor uses the persisted game's slug without adding a second client-owned identity mapping.

Tests cover TypeID and slug schema/database constraints, all nineteen backfilled slug/BGG/stage/engine bindings, context lookup by id and slug, ordering/enrichment/fallback, slug navigation, both disabled creation endpoints, existing disabled/edited Sessions, captured engine behavior, Session/Scope/channel authorization, Workspace JSON and AsyncAPI, slug module subdomain with TypeID claim/CORS, Backpex create and immutable-slug behavior, the shared administrator-role gate, Bodyguard resource policy, forged-role non-escalation, and frontend navigation/launch hiding. Browser validation covers anonymous, non-admin, and admin `/dashboard` access; game creation and edits; duplicate/invalid slug errors; disabled detail UI; slug routes; and desktop/narrow Backpex rendering.

Unit tests alone were rejected because this change crosses database, HTTP, LiveView, channel, iframe, and browser asset seams.

## Risks / Trade-offs

- [Backpex 0.x interfaces can change] -> Pin to the compatible `~> 0.20.0` line, use standard fields/routes only, and cover the resource through LiveView and browser tests.
- [A migrated slug, binding, or enum number is wrong] -> Assert all nineteen slug/BGG/stage/engine bindings after migration plus unique valid TypeIDs and preserved K-sort order.
- [An operator changed BGG bindings before slug backfill] -> Audit all current rows before migration, map canonical slugs only through the expected unique former BGG bindings, and abort rather than assign a guessed slug when the expected set differs.
- [An existing database already ran the slugless migration] -> Add slug through a forward additive migration with explicit backfill before making it non-null; never reset or drop unrelated data.
- [Slug is renamed casually] -> Exclude it from ordinary update changesets and edit forms; require a separately planned data, repository, DNS, and Pages migration for rename.
- [Operator changes BGG or engine accidentally] -> Database constraints reject malformed combinations; stable id and captured Session engine limit the blast radius. Audit/reason workflows remain intentionally out of scope.
- [An engine changes while Sessions are running] -> Existing server tuples retain the old engine; only later `Sessions.create` calls receive the edited engine.
- [Disabled games disappear from a running Workspace] -> Workspace ignores launch flags and resolves by stable id, so existing sessions remain present.
- [Slug hosts and application routing drift] -> Backfill the exact former slugs, retain existing repository/Traefik/Pages names, remove TypeID aliases only after corrected D20 framing is verified, and smoke-test every implemented engine.
- [Administration entry and catalog resource authorization are conflated] -> Require the persisted administrator role consistently at HTTP and LiveView boundaries, re-resolve it before Backpex initialization, and keep catalog action checks in `GameLive.can?/3`.
- [Old release cannot observe admin edits] -> Application rollback is possible but restores checked-in catalog behavior; export current rows before destructive schema rollback.
- [The pending developer-page change reintroduces Registry] -> Reconcile its unfinished registry-dependent task against static specification identifiers before archiving either change.

## Migration Plan

1. Audit existing game rows against the nineteen expected unique former BGG bindings. Add a forward migration that introduces nullable slug, backfills only exact verified mappings, aborts on drift, adds format/length/unique constraints, and then makes slug required. Keep generated environment-local TypeIDs unchanged.
2. Add create and update changesets plus lookup by slug; update browser routes/props to slug while retaining TypeID-based Session, Workspace, module HTTP, socket, and token contracts.
3. Extend Backpex with authorized game creation, required slug input, read-only post-create slug, and no delete action.
4. Validate local slug hosts against the existing standalone repository Traefik aliases.
5. In Infra, retain the explicit canonical Pages project/domain set and remove TypeID-to-Pages aliases only after slug framing is deployed and verified. Do not add backend-query reconciliation in this change.
6. Take a database backup, run migrations, deploy D20, and smoke-test catalog/detail/module/Session flows for every implemented engine.
7. Assign `admin` through trusted database access where still required, and verify anonymous, ordinary-user, and administrator create/edit behavior.
8. Verify that disabling a game blocks both new-Session HTTP paths while a pre-existing Session remains connected, and verify that engine edits affect only newly created Sessions.

For application rollback, deploy the preceding TypeID-route code while leaving the additive slug column and explicit slug-based Infra resources in place; that code ignores slug and TypeID aliases can be restored temporarily if necessary. Do not drop slug during the first rollback response. Before any destructive schema rollback, stop new-code traffic and export/backup `games` plus administrator assignments.

## Open Questions

None.
