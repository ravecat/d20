## ADDED Requirements

### Requirement: Interest records use the authoritative resolved game identity
The system SHALL retain a positive BGG ID separately from presentation Metadata for every successfully resolved detail. An exact local match SHALL use its persisted `bgg_id`; provider fallback SHALL use the parsed provider identity. Interest SHALL use that BGG identity without parsing route slugs, requiring a local Game, or changing exact-slug-first resolution. The page SHALL expose `interest` with a server-generated original-route `action`, the current account's persisted `requested` boolean, and a numeric `count` of distinct requesting accounts for the resolved BGG game. Guest membership SHALL be false. Interest submission SHALL require no BGG ID payload. The current server-resolved BGG ID SHALL determine the subject, and supplied BGG IDs SHALL be ignored.

#### Scenario: Local and provider detail share one subject
- **WHEN** an account requests eligible local and provider-only pages that resolve BGG game 183006
- **THEN** both actions address the same account/game membership and grouped count
- **AND** no local Game is inserted and neither route is reassociated or redirected to another slug

#### Scenario: Canonical numeric slug would select another local game
- **WHEN** `/games/00183006` resolves provider game 183006 but exact local slug `183006` belongs to another BGG game
- **THEN** the action uses `/games/00183006/interest` with no BGG ID payload
- **AND** submission and its redirect preserve the original detail route and cannot count the unrelated local game

#### Scenario: Binding changes after rendering
- **WHEN** a route binding changes after rendering and an authenticated account submits for that still-eligible route
- **THEN** the new request uses the current server-resolved BGG ID without comparing it to page-load identity
- **AND** previously stored requests remain attached to their original BGG ID

#### Scenario: Local metadata provider is unavailable
- **WHEN** a visible non-playable local detail uses metadata fallback
- **THEN** its persisted BGG binding still identifies the interest subject
- **AND** empty presentation metadata does not prevent a valid account request

### Requirement: Interest submission enforces account and page eligibility
The system SHALL accept `POST /games/:slug/interest` only for an authenticated server account and a freshly resolved detail that is visible without a Session exception and has `playable: false`. Existing browser CSRF protection SHALL apply. The endpoint SHALL derive the user from authentication, ignore supplied user and BGG identities, and use current route resolution for persistence. Missing/provider-failed or hidden local details SHALL return 404 without writing. An already playable detail SHALL redirect to the original page without an error, success, or availability message and without a new request. Existing Session and launch endpoint behavior SHALL remain unchanged.

#### Scenario: Interest rules apply through the context boundary
- **WHEN** application code calls `D20.Games.Interests.request(user, slug)` directly
- **THEN** the Interests context uses Games to resolve the original route and check visibility/playability before persisting interest
- **AND** controllers and other callers use `Interests.request/2`, `requested?/2`, and `counts/0` directly, without redundant interest delegates on Games
- **AND** callers receive the same success or error result without requiring a controller to enforce these rules
- **AND** HTTP controllers only pass request values and translate context results into responses; they perform no identity casting, eligibility checks, or database queries for interest

#### Scenario: Authenticated account requests an unavailable game
- **WHEN** an authenticated account submits with no payload for an eligible detail
- **THEN** the server records that account's interest and returns a 303 redirect to the original detail route
- **AND** it creates no Session and exposes no other account's data

#### Scenario: Direct guest or forged-account request
- **WHEN** a guest posts directly or an authenticated caller supplies another user's ID
- **THEN** no guest or impersonated-account contribution is written
- **AND** guests follow the existing authentication-required flow without an automatic write after sign-in

#### Scenario: Hidden detail is submitted directly
- **WHEN** an exact local match has a stage outside the configured visible stages
- **THEN** interest submission returns 404 even when launchability is false or a Session ID is supplied

#### Scenario: Direct request for a playable game
- **WHEN** an authenticated account posts directly for an already playable game
- **THEN** no request is inserted and the controller returns a plain 303 redirect to the original detail
- **AND** no error or success message is assigned

#### Scenario: Availability changes before submission
- **WHEN** a displayed unavailable game becomes playable before its interest POST is checked
- **THEN** no new request is inserted and the redirect refreshes the original detail without an error, success, or availability message
- **AND** prior interest remains stored

### Requirement: One durable contribution exists per account and BGG game
The system SHALL persist `game_interests` with an autogenerated `id` of type `TypeID` and prefix `interest`, non-null `user_id`, positive `bgg_id`, and a UTC first-request timestamp. PostgreSQL SHALL enforce the `id` primary key, a unique account/game index, and a user foreign key with delete cascade. Duplicate requests and concurrent retries SHALL have the same successful outcome while preserving the original ID, timestamp, and one contribution. Non-duplicate database errors SHALL remain failures. The table SHALL NOT require a local Game or persist provider presentation fields.

#### Scenario: A request receives a typed identity
- **WHEN** an authenticated account saves a new interest
- **THEN** the persisted row has an autogenerated interest-prefixed TypeID as its primary key

#### Scenario: Repeated and simultaneous submissions
- **WHEN** one account sends repeated or concurrent requests for one eligible BGG game
- **THEN** exactly one row exists and contributes one to that game's total
- **AND** every successful duplicate response reports saved membership without changing the original interest ID or first timestamp

#### Scenario: Distinct accounts and distinct games
- **WHEN** two accounts request one BGG game and one of those accounts requests a second game
- **THEN** the first game's total is two and the second game's total is one

#### Scenario: Database integrity is enforced
- **WHEN** a write omits account or BGG identity, uses a nonexistent user, or uses a nonpositive BGG ID
- **THEN** database constraints reject the invalid row

#### Scenario: Account is deleted
- **WHEN** an account is deleted through an authorized account lifecycle operation
- **THEN** its interest rows are removed through the user foreign key
- **AND** derived totals immediately exclude those contributions

### Requirement: Operators can count authoritative requests
The system SHALL provide an internal grouped-count query returning BGG ID and account-request count from persisted interest rows. An index SHALL support BGG grouping. No separately mutable total, HTTP ranking, or dashboard SHALL be introduced. Requests SHALL remain associated with their BGG game when local catalog bindings or playability change.

#### Scenario: Operators inspect demand
- **WHEN** trusted operator code queries grouped interest counts
- **THEN** the result counts one authoritative row per account/game pair
- **AND** no account identifiers or profiles are included in that aggregate result

### Requirement: Guests use existing authentication before explicitly requesting
A guest activating `I want this game!` SHALL open the existing shared account dialog with the safe original detail return path. Closing or completing authentication SHALL NOT record or replay an interest request. After sign-in the account SHALL explicitly activate the action to submit. Existing provider-only accounts SHALL qualify without adding an email requirement.

#### Scenario: Guest signs in from interest
- **WHEN** a guest activates interest and successfully authenticates
- **THEN** the existing flow returns to the original detail path
- **AND** no interest is created until the account explicitly submits

#### Scenario: Guest dismisses authentication
- **WHEN** a guest closes the account dialog
- **THEN** the detail remains available and no request has been recorded

### Requirement: Interest feedback reflects persisted state and supports retry
The interest submission form SHALL be named `InterestForm` and implemented in `assets/js/pages/game/ui/interest_form.svelte`. Its initial content SHALL expose one visible button with the exact accessible name `I want this game!`. While submitting, it SHALL expose a pending `Saving...` state and prevent duplicate activation. Saved state SHALL depend on refreshed server-backed membership and display `Requested` as an unavailable action without a separate success message below the button. Server-reported persistence and validation failures SHALL use the `interest` error bag with general field `message` (`errors.interest.message` on the page and `errors.message` in the scoped Form snippet) and SHALL expose an adjacent alert and restore a retryable initial action without falsely claiming success. Confirmed membership SHALL suppress stale submission errors. Transport failure after a commit SHALL remain safe to retry. The control SHALL preserve native keyboard semantics and visible focus. `InterestForm` SHALL contain no game setup fields or `BasicForm`; submission SHALL use the Svelte Inertia `Form` component directly. Form SHALL own submission, processing, and scoped server errors; `onBefore` SHALL cancel guest and already-requested submissions. Network errors and unexpected HTTP responses SHALL use standard Inertia handling without a custom inline error message.

#### Scenario: Initial interest form is displayed
- **WHEN** a non-playable detail has no Session and the caller has no saved request
- **THEN** `InterestForm` presents the single visible button `I want this game!`
- **AND** no game setup fields, `BasicForm`, or `SessionForm` are rendered

#### Scenario: Successful save and reload
- **WHEN** an authenticated request commits and the page reloads or is revisited under the same account
- **THEN** persisted membership renders the saved state without another contribution
- **AND** the disabled `Requested` button confirms the save without a separate success message below it
- **AND** the per-game count reflects persisted requests and other accounts' identities remain absent

#### Scenario: Server reports a submission failure
- **WHEN** the server returns a scoped persistence or validation error
- **THEN** the Form error is shown in an adjacent alert and the action permits retry without claiming success

#### Scenario: Network failure or unexpected HTTP response
- **WHEN** the response is lost or is not a valid Inertia response
- **THEN** standard Inertia error handling applies and the form exits processing without claiming saved membership
- **AND** a retry after a previously committed insert still contributes at most one row

### Requirement: Game visibility is owned by the Games context
The Games context SHALL expose `visible?/1` for a local Game based only on its membership in configured visible stages. Page detail, interest eligibility, and session launch eligibility SHALL reuse that predicate instead of reading the configuration in dependent modules. Disabled and engine-less games SHALL remain visible when their stage is permitted. The existing Session exception and provider-only handling SHALL remain unchanged. Games list queries SHALL retain SQL filtering and ordinary fetch functions SHALL retain their current lookup behavior.

#### Scenario: Visibility does not require launch availability
- **WHEN** a disabled or engine-less local game has a configured visible stage
- **THEN** `Games.visible?/1` returns true even though new-session launch is unavailable

#### Scenario: Configuration determines visible stages
- **WHEN** a local game stage is removed from configured visible stages
- **THEN** `Games.visible?/1` returns false and dependent operations retain their existing hidden-game behavior

### Requirement: Interest action shows the authoritative request count
The detail SHALL expose `interest.count` for its resolved BGG game to guests and authenticated callers. `InterestForm` SHALL display that numeric count, including zero, then a decorative five-point SVG star, then its current button label. The button SHALL retain its action accessible name and expose the count as an accessible description. Pending, saved, and error states SHALL retain the count. Refreshed server props SHALL update it after a request; the client SHALL NOT optimistically increment it or expose requester identities.

#### Scenario: No requests exist
- **WHEN** a resolved game has no saved requests
- **THEN** its interest button displays zero followed by the star and action label

#### Scenario: Requests are saved or repeated
- **WHEN** two accounts save interest for the same resolved BGG game and either repeats its request
- **THEN** local and provider-only details expose count two, including after reload
- **AND** a pending or failed submission does not invent another contribution

#### Scenario: Count is accessible and adapts to narrow layouts
- **WHEN** a caller uses a screen reader or a narrow viewport
- **THEN** the action remains clearly named, its count is available as a description, and the count, star, and label remain visible without horizontal overflow
