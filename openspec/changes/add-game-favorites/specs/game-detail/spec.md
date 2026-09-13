## ADDED Requirements

### Requirement: Detail hero exposes a reversible favorite button

Every successfully rendered local or provider-only detail SHALL display the same icon-only FavoriteButton used by Home at the top right of the cover, with caller-specific membership from resolved BGG identity. The detail page SHALL import named `FavoriteButton` from `~/features/favorite-game` and retain `title={game.name}` without variant or authenticated props. FavoriteButton SHALL check current page auth inside its own submission guard; independent SessionForm/InterestForm authentication SHALL remain unchanged. The button SHALL have no visible Add/Remove or Saving/Removing label, detail text-button box or detail-specific styling. Its accessible action SHALL follow the complete title-aware or generic messages defined by game-favorites, directly in markup. The unchanged SVG SHALL retain CSS-owned gold outline and resting transparent/gold membership fill plus the shared hover/focus preview. The button SHALL retain hero placement across launchable, unplayable, existing-Session and fallback-cover states without modifying the activation panel. It SHALL retain icon-sized bounds, visible focus, aria-pressed, local aria-busy/aria-disabled, same-control retry without custom notices and existing authentication semantics.

#### Scenario: Game is launchable

- **WHEN** a launchable game detail is rendered
- **THEN** its hero contains the favorite button and its activation panel retains master's existing `SessionForm` using the `playable` contract

#### Scenario: Game has an existing Session

- **WHEN** a validated Session is rendered
- **THEN** the hero favorite remains usable independently of the Lobby and exposes the same Session-free descriptor as detail without a Session
- **AND** saving or removing preserves the Session query and existing Session state

#### Scenario: User changes favorite state

- **WHEN** an authenticated user activates the hero button
- **THEN** its Inertia form submits the explicit PUT or DELETE determined by the server favorites prop to the same query-free `favorite.action` at `/favorites/<bggId>`
- **AND** PUT carries the descriptor's original slug and current response target, while DELETE carries only the response target
- **AND** neither method submits a runtime Session field or redundant `bgg_id`; any Session query remains only in the safe return-page URL
- **AND** while its own Form is processing it retains its title-aware or generic Add/Remove accessible action, exposes aria-busy/aria-disabled, retains focus and prevents repeat activation without visible processing text; confirmed props update its accessible action and pressed state without a notification
- **AND** the resting star retains its confirmed transparent or gold interior during pending/error, with the existing temporary hover/focus preview allowed, and retains its gold outline

#### Scenario: Mobile or fallback cover is rendered

- **WHEN** the page has a narrow viewport, long title, or missing image
- **THEN** the favorite button remains inside the cover without overlapping the title or metadata chips
- **AND** the remaining detail content retains its existing responsive layout

### Requirement: Favorite reloads preserve ordinary detail resolution

Every detail request, including an Inertia partial refresh after a favorite mutation, SHALL resolve the original game route and validate any supplied Session before rendering through the existing detail flow. Existing not-found responses, Session-error redirects, visibility policy, and flat prop structure SHALL remain unchanged. PageController SHALL retain `D20.Games.resolve_session/2` for ordinary detail validation beside route loading without a separate Detail module or extra lookup. Favorite mutations SHALL resolve only source game data and BGG identity without invoking that policy. Favorites and independently computable launch schema SHALL use lazy props selected by the standard Inertia adapter. The controller SHALL NOT add a favorites-only partial response branch, duplicate resolution, memoization, or a new exception framework. Successful partial responses SHALL merge requested favorites/auth/errors while retaining unrequested client game, launch, and Session props.

#### Scenario: Favorite redirect refreshes valid detail

- **WHEN** a favorite form returns to a still-valid game route and Session query requesting favorites, auth, and errors
- **THEN** the controller performs ordinary game and Session validation before rendering
- **AND** the response refreshes requested membership/auth/errors and omits unrequested schema/game/Session props, preserving their existing client values
- **AND** acceptance does not depend on whether the adapter evaluates the unrequested schema callback

#### Scenario: Provider becomes unavailable before removal

- **WHEN** the account removes a favorite and BGG cannot resolve the provider-only detail on the following GET
- **THEN** the DELETE mutation remains successful and provider-independent
- **AND** the redirected detail GET returns the ordinary resolution failure rather than bypassing it
- **AND** a later valid page load reflects the persisted removal

#### Scenario: Session becomes invalid before refresh

- **WHEN** a favorite redirect returns to detail with a missing or mismatched Session
- **THEN** the detail GET follows the existing Session-error response or redirect independently of the preceding favorite mutation
- **AND** a partial prop request does not bypass route visibility or Session validity
- **AND** a successfully persisted favorite mutation is not reversed or rejected because the return-page Session is invalid

#### Scenario: Error response returns to valid detail

- **WHEN** a favorite form redirects with authentication or favorite errors to a game/Session context that still resolves successfully
- **THEN** the requested error fields reach the form through the normal Inertia response
- **AND** authentication errors retain the existing dialog while favorite errors preserve confirmed membership and allow retry without a custom notice
- **AND** favorite processing does not mutate game or Session state

#### Scenario: Full detail needs launch schema

- **WHEN** a successful full detail response requires a launch schema
- **THEN** its lazy schema calculation supplies the existing schema value and flat prop shape
- **AND** provider-only or otherwise schema-free detail retains the existing null value

### Requirement: Detail stories preserve activation and favorite states together

The game-detail Storybook file SHALL retain `WithoutSession`, `WithSession`, `UnavailableGame`, `Requested`, `HeaderFocused`, `FavoriteSaved`, `FavoritePending`, `FavoriteError`, `LongTitleFallback`, and `UntitledFallback`. Each SHALL supply `{bggId, action, slug}` with a single query-free resource action, original source slug and no Session member, plus an appropriate favorites array; WithSession SHALL retain its runtime Session only in the ordinary page props and return URL. Existing socket/session and Inertia mock initialization and cleanup SHALL remain isolated between stories. Each state SHALL be declared once without a theme-only duplicate or story-level theme override. Semantic story source SHALL cover the icon-only hero star, complete title-aware or generic accessible action, stable pending action with aria-busy, no visible label, confirmed-state failure/retry without notifications, and existing focus and Session/interest behavior. Retain story IDs, including FavoriteError, without favorite alert/status assertions. The existing light/dark by desktop/tablet/mobile matrix remains unchanged, but Storybook execution, screenshots/reference updates and rendered review are explicitly waived for the notification-removal, page/feature ownership, single-icon-control and page-authentication ownership amendments; existing story paths, titles, IDs and screenshot files SHALL remain unchanged during the ownership relocation. Wider visual gates remain open and historical screenshots do not establish the new behavior.

#### Scenario: Existing master stories render favorites

- **WHEN** WithoutSession, WithSession, UnavailableGame, Requested, or HeaderFocused is rendered
- **THEN** its existing Play, Lobby, interest request, Requested, or focused-heading state remains correct
- **AND** a favorite star with matching descriptor/membership renders on the hero

#### Scenario: Favorites stories remain available after integration

- **WHEN** saved, pending, error, long-title, or untitled favorites detail is rendered in either native theme
- **THEN** its favorite treatment and activation contract remain valid under the current playable/interest props
- **AND** mock state from a preceding Session or interest story does not leak into it

#### Scenario: Detail references follow the shared theme matrix

- **WHEN** the ten detail stories run through the native visual projects
- **THEN** each receives a reviewed light and dark reference at desktop `1280x720`, tablet `1024x640`, and mobile `320x900`
- **AND** all 60 references use `<story-path>/<theme>/<viewport>/chromium/<scenario>-1.png`
- **AND** obsolete unthemed references and `FavoriteSavedDark` references are removed after their matrix replacements are reviewed
- **AND** normal comparison passes without changing the shared screenshot infrastructure

## MODIFIED Requirements

### Requirement: Provider-only detail pages have no local runtime identity

A resolved provider-only detail SHALL render the existing game page with `id: null`, a decimal BGG string as `slug`, `stage: null`, `playable: false`, resolved `game` Metadata, `schema: null`, and `session: null`. It SHALL also expose the game-interest contract containing the original-route action URL, the current account's saved membership, and the resolved game's request count. The former `can_launch_game` / `canLaunchGame` prop SHALL be absent. Local detail IDs SHALL retain their TypeID meaning; catalog IDs SHALL retain their numeric BGG meaning. The page SHALL display metadata and `InterestForm` with its request action or saved state without `SessionForm`, Play control, local Session, or invented Game record. It SHALL additionally expose the static favorite descriptor and private favorites membership prop and display the independent favorite form on the hero.

#### Scenario: Provider-only detail props are serialized

- **WHEN** BGG confirms a game without a selected local detail record
- **THEN** the response contains its normalized numeric route slug and Metadata with null local identity, stage, schema, and Session
- **AND** playable is false and interest contains the original-route action, caller membership, and request count without a BGG ID field
- **AND** canLaunchGame is not serialized
- **AND** favorite identity/action/source context and current-account favorites membership are available independently of interest

#### Scenario: Provider-only detail is displayed

- **WHEN** the client receives provider-only detail props
- **THEN** metadata and description render through the existing detail layout
- **AND** the activation panel renders `InterestForm` with `I want this game!` or persisted saved state without Play, disabled Play, `SessionForm`, or Lobby
- **AND** the hero retains its independent favorite star and add/remove action

#### Scenario: Provider-only detail fails to resolve

- **WHEN** the provider omits the requested game or configuration, HTTP, transport, parse, or Metadata validation fails
- **THEN** the context returns the error and the controller returns its existing 404 response
- **AND** the system does not invent a successful empty detail page or persist a Game
