# game-detail Specification

## Purpose
Define internal detail navigation and runtime metadata presentation for local and provider-only games through string route slugs.
## Requirements
### Requirement: Catalog tile opens game detail page
The system SHALL allow users to open every delivered catalog game's detail page inside D20 through `/games/:slug`. The Games context SHALL provide the non-null route slug before serialization: the visible local record's stored slug or the BGG ID as a decimal string. Runtime names SHALL remain presentation only. Canonical cards SHALL use one uniform internal Inertia link without external BGG redirects or frontend fallback-slug selection.

#### Scenario: Tile click navigates by internal slug
- **WHEN** the user activates the delivered Qwinto tile with local slug `qwinto`
- **THEN** the system navigates to `/games/qwinto`

#### Scenario: Local tile retains its stored slug
- **WHEN** the visible Qwinto row has `bgg_id` 183006 and slug `qwinto`
- **THEN** its catalog target remains `/games/qwinto`
- **AND** neither its BGG ID nor local TypeID replaces the stored route slug

#### Scenario: Provider-only tile has an internal detail target
- **WHEN** the context returns BGG game 224517 without a visible local association
- **THEN** its route slug is `224517` and its card links to `/games/224517`
- **AND** activation remains inside D20 through the same Inertia navigation as local cards

### Requirement: Game detail page uses runtime metadata
The system SHALL use runtime Metadata for local and provider-only detail presentation. The existing title, preview, description, player-count, time, age, complexity, rating, category, and mechanic treatments SHALL use available values. Missing optional fields SHALL retain existing fallback treatments without deriving a title or route slug from presentation data. A successful provider-only request SHALL use `BoardGameGeek.fetch_game/1` and the existing embedded Metadata schema without requiring Hot membership or creating a local Game.

#### Scenario: Detail page renders runtime title
- **WHEN** runtime metadata for `qwinto` includes title `Qwinto`
- **THEN** the `/games/qwinto` detail page presents `Qwinto` as the game title

#### Scenario: Detail page renders runtime preview image
- **WHEN** runtime metadata for `qwinto` includes a preview image URL
- **THEN** the `/games/qwinto` detail page presents that image as the game preview

#### Scenario: Detail page renders runtime description
- **WHEN** runtime metadata for `qwinto` includes a description
- **THEN** the `/games/qwinto` detail page presents that description

#### Scenario: Numeric detail is opened directly
- **WHEN** BGG game 224517 has no selected local detail record and a user opens `/games/224517` directly
- **THEN** the context requests that ID through fetch_game and renders the returned Metadata
- **AND** no Hot request, local insert, engine binding, or synthetic TypeID is required

#### Scenario: Runtime metadata omits optional fields
- **WHEN** a successful provider detail has no image or description
- **THEN** the page uses its existing fallback preview and description treatment
- **AND** available metadata is still displayed

### Requirement: Game detail page resolves local and provider games
The Games context SHALL resolve `GET /games/:slug` through an exact persisted slug lookup first. A matching local row SHALL retain its persisted TypeID and slug, current visibility policy, launch authorization, metadata fallback, and existing Session matching. After an exact slug miss, resolution SHALL NOT query local rows by BGG ID or redirect to another stored slug. The context SHALL pass the original string directly to BoardGameGeek.fetch_game without regex or integer input validation and SHALL inline fetching and Metadata construction in the missing-record branch. A successful single parsed provider game SHALL determine the canonical decimal BGG route slug. Provider errors, missing games, or ambiguous multi-game results SHALL remain errors. An exact numeric local slug SHALL take precedence over the provider fallback. Hidden local slug matches SHALL remain terminal under current visibility policy, subject only to the validated matching-Session exception.

#### Scenario: Registered game detail page is found
- **WHEN** the user opens `/games/qwinto` and its persisted record is visible
- **THEN** the context resolves that row by stored slug and the controller renders its existing detail page
- **AND** local detail props retain its TypeID string and persisted slug

#### Scenario: Unknown game detail page is not found
- **WHEN** the user opens `/games/missing` with no matching local slug and the provider returns no game
- **THEN** the context sends `missing` unchanged as the provider id parameter and the controller returns 404

#### Scenario: Numeric local slug takes precedence
- **WHEN** a local row has the exact slug `224517` and a different BGG binding
- **THEN** `/games/224517` resolves that local row and uses its actual BGG binding for metadata
- **AND** the route is not interpreted as a request for BGG game 224517

#### Scenario: Numeric ID also belongs to a local row under another slug
- **WHEN** no exact slug `183006` exists but Qwinto has BGG ID 183006 and stored slug `qwinto`
- **THEN** `/games/183006` resolves provider-only metadata without Play or a local identity
- **AND** `/games/qwinto` retains local detail and launch behavior, and the visible joined catalog entry still links to that stored slug
- **AND** the numeric request is not redirected to `/games/qwinto`

#### Scenario: Hidden row has the same BGG ID under a different slug
- **WHEN** numeric fallback resolves a BGG ID also bound to a hidden local row under another slug
- **THEN** the provider-only detail contains no local stage, TypeID, engine, or launch capability
- **AND** the hidden stored-slug route retains its existing visibility behavior

#### Scenario: Leading zeroes identify the same provider game
- **WHEN** no exact slug matches `00183006`
- **THEN** fallback sends string `00183006` to BGG and provides route slug `183006` when the returned game ID is 183006
- **AND** no canonical HTTP redirect is required

#### Scenario: Unmatched route strings are delegated unchanged
- **WHEN** no local slug matches a supplied string such as `0`, `-1`, `+1`, `1.5`, `1e3`, `183006suffix`, or a value containing whitespace
- **THEN** the context delegates that original string without syntax rejection and the adapter sends it using encoded query params
- **AND** a provider error, missing game, or multi-game response results in 404

#### Scenario: Returned identity supplies the route slug
- **WHEN** the provider resolves an unmatched route string to one parsed game with positive ID 183006
- **THEN** the context builds Metadata and returns provider-only detail slug `183006` from the returned identity

#### Scenario: Hidden local slug is not replaced by provider data
- **WHEN** an exact local slug matches a hidden-stage game without a validated matching Session
- **THEN** the current visibility or Session-error behavior is preserved
- **AND** the controller does not retry the value as a provider-only page

### Requirement: Provider-only detail pages have no local runtime identity
A resolved provider-only detail SHALL render the existing game page with `id: null`, a decimal BGG string as `slug`, `stage: null`, `playable: false`, resolved `game` Metadata, `schema: null`, and `session: null`. It SHALL also expose the game-interest contract containing the original-route action URL, the current account's saved membership, and the resolved game's request count. The former `can_launch_game` / `canLaunchGame` prop SHALL be absent. Local detail IDs SHALL retain their TypeID meaning; catalog IDs SHALL retain their numeric BGG meaning. The page SHALL display metadata and `InterestForm` with its request action or saved state without `SessionForm`, Play control, local Session, or invented Game record.

#### Scenario: Provider-only detail props are serialized
- **WHEN** BGG confirms a game without a selected local detail record
- **THEN** the response contains its normalized numeric route slug and Metadata with null local identity, stage, schema, and Session
- **AND** playable is false and interest contains the original-route action, caller membership, and request count without a BGG ID field
- **AND** canLaunchGame is not serialized

#### Scenario: Provider-only detail is displayed
- **WHEN** the client receives provider-only detail props
- **THEN** metadata and description render through the existing detail layout
- **AND** the activation panel renders `InterestForm` with `I want this game!` or persisted saved state without Play, disabled Play, `SessionForm`, or Lobby

#### Scenario: Provider-only detail fails to resolve
- **WHEN** the provider omits the requested game or configuration, HTTP, transport, parse, or Metadata validation fails
- **THEN** the context returns the error and the controller returns its existing 404 response
- **AND** the system does not invent a successful empty detail page or persist a Game
