# game-favorites Specification

## Purpose
Define private durable account favorites and their shared Home/detail interaction, identity, HTTP and authentication contracts.

## Requirements

### Requirement: The Favorite Game feature owns the reused interaction

The shared Home/detail favorite interaction SHALL reside at `assets/js/features/favorite-game/ui/favorite-button.svelte`. Its slice `index.ts` SHALL export named `FavoriteButton` from the component's default export. Home's GameCard and the game detail page SHALL import it through `~/features/favorite-game`, without reaching into feature internals. The old `assets/js/shared/components/favorite_button.svelte` path SHALL be removed without a compatibility alias or re-export. The feature SHALL expose one icon-only control with favorite/saved/title/tabindex inputs and without an icon/detail `variant` or `authenticated` prop. It SHALL read current `page.props.auth.authenticated` directly in its existing beforeSubmit guard through usePage on each submission attempt. Request fields and methods, authentication callbacks, local Form processing, confirmed membership and failure/retry semantics SHALL remain unchanged. Existing Shared types and infrastructure SHALL retain their ownership.

#### Scenario: Both pages consume the same interaction

- **WHEN** Home renders a card favorite or detail renders its hero favorite
- **THEN** the page-owned consumer imports FavoriteButton from the feature public API
- **AND** both consumers use the same icon-only control with unchanged saved state, authentication and request behavior

#### Scenario: The old component location is inspected

- **WHEN** production favorite imports are checked after relocation
- **THEN** no source imports or exposes FavoriteButton through the former Shared component path
- **AND** no duplicate implementation, old `features/toggle-game-favorite` slice or compatibility alias remains

### Requirement: Favorites are durable private account membership

The system SHALL persist one favorite per authenticated account and BGG game ID in `game_favorites`, with a composite uniqueness constraint, an account foreign key with delete cascade, and the first-save timestamp. Favorites SHALL survive logout, reload, and authenticated visits from another device until explicitly removed or the account is deleted. They SHALL NOT require a local Game row or alter launch eligibility.

#### Scenario: Favorites do not impose numeric ID range rules

- **WHEN** an integer BGG ID is cast into a Favorite changeset
- **THEN** Favorite SHALL NOT validate its sign or numeric range
- **AND** the favorites migration SHALL NOT create a positive-ID CHECK constraint
- **AND** integer storage, required identity fields, account foreign key/cascade and composite uniqueness SHALL remain enforced

#### Scenario: Account saves and revisits a game

- **WHEN** an account saves a game and later revisits its detail from another authenticated device
- **THEN** the game is saved for that account
- **AND** other accounts and guests do not receive its membership

#### Scenario: Duplicate and concurrent additions

- **WHEN** multiple add requests for one account and BGG ID succeed
- **THEN** exactly one association exists with its original save timestamp
- **AND** only duplicate-key conflicts are treated as successful no-ops

#### Scenario: Removal is repeated

- **WHEN** the account removes a favorite that is already absent
- **THEN** the operation succeeds with absent membership
- **AND** favorites belonging to other accounts remain unchanged

#### Scenario: Account is deleted

- **WHEN** an account is deleted
- **THEN** its favorites are removed by the database relationship

#### Scenario: Catalog availability or binding changes

- **WHEN** a saved game's local row is disabled, removed, or bound to another BGG game
- **THEN** the favorite stays attached to the original BGG ID
- **AND** it neither moves to the new binding nor makes an unavailable game launchable

### Requirement: Writes use authoritative game and caller identity

Adding a favorite SHALL resolve the original `slug` supplied as form data through `Games.fetch_by_slug/1`, preserving existing local-first game-data resolution without checking detail visibility or resolving a runtime Session. Hidden local records SHALL be eligible when their resolved BGG identity matches the expected identity. Any extraneous `session` input SHALL have no effect on the mutation. The BGG ID in the URL SHALL be the expected-identity precondition, never sufficient authority for adding; body/query fields SHALL NOT override it. Removal SHALL address only the authenticated account's association by BGG ID without requiring current catalog visibility or provider availability. Client-supplied user IDs SHALL NOT select the owner.

#### Scenario: Local and provider routes identify one game

- **WHEN** a local route and a provider-only route resolve to the same BGG ID
- **THEN** both project and modify the same account favorite
- **AND** no local catalog row is created for provider-only resolution

#### Scenario: Normalized numeric slug would collide

- **WHEN** the original route `00183006` resolves BGG 183006 but exact local slug `183006` has another binding
- **THEN** the descriptor preserves `slug: "00183006"` and uses `action: "/favorites/183006"` for both methods
- **AND** PUT resolves that original form slug and compares the result with path ID 183006
- **AND** it does not resolve the add through the normalized slug

#### Scenario: Binding changes after render

- **WHEN** an add action resolves a different BGG ID from its URL BGG ID
- **THEN** no favorite is added and the Inertia return response carries a favorite error explaining that the game identity changed

#### Scenario: Hidden local source identifies the requested game

- **WHEN** the exact local source is hidden and its resolved BGG ID matches the authenticated add request
- **THEN** the favorite is saved without requiring a runtime Session or checking detail visibility
- **AND** ordinary detail GET access remains governed by its existing visibility and Session policy

#### Scenario: Runtime Session context varies

- **WHEN** otherwise equivalent authenticated add requests omit `session` or include a valid, nonexistent, mismatched or malformed Session value
- **THEN** each resolves the same source game and has the same mutation result
- **AND** no runtime Session is looked up, created or modified

#### Scenario: Provider is unavailable during removal

- **WHEN** an account removes its favorite while BGG cannot resolve the game
- **THEN** the DELETE mutation succeeds using the account and BGG identity without a provider request
- **AND** a redirected detail GET still follows ordinary route resolution and can fail independently of that persisted removal

### Requirement: Favorite validation belongs to domain contexts

`D20.Games.Favorites` SHALL expose validated `create/3` and `delete/2` commands without intermediate save/add/remove mutation APIs. Each command SHALL call Repo directly, preserving returned changeset errors and successful :ok results. Database and connection exceptions SHALL propagate through the existing Phoenix error boundary without a transient-error list, custom unavailable reason, rescue or replacement handler. `D20.Games.Favorites` SHALL own account requirements, add-source resolution and identity checks, and source-independent removal. `GameFavoriteController` SHALL only delegate inputs and render the existing HTTP/Inertia outcome; it SHALL NOT contain a private account plug, custom ID validator, source resolver or identity comparison. Creation SHALL take only account, expected BGG ID and original slug, with no Session argument or compatibility overload. Favorites SHALL accept the caller-provided `String.t()` slug under the existing resolver input contract without additional type/emptiness validation and call `Games.fetch_by_slug/1` directly in `create/3` with a case expression without a private source-resolution wrapper, `Games.resolve_session/2` or a visibility predicate. Its result branches SHALL preserve `:game_not_found` for returned source-resolution failures and `:game_identity_changed` for a successfully resolved different BGG identity, without normalizing persistence-body results or catching unexpected input-contract exceptions. Ordinary detail visibility and matching-Session validation SHALL remain in `D20.Games.resolve_session/2` for PageController, with web-owned channel topics and no domain dependency on `D20Web`.

#### Scenario: Context receives a guest

- **WHEN** create or delete is called directly with a missing account
- **THEN** the context returns the existing authentication reason without a write or game/provider resolution

#### Scenario: Supported links supply the expected ID

- **WHEN** a caller submits a favorite action generated by the application
- **THEN** the HTTP boundary converts the path ID with standard String.to_integer/1 and supplies an integer to the context
- **AND** no custom ID format/range validator or invalid_bgg_id form error is provided for malformed handcrafted IDs
- **AND** account ownership, source identity checks, required fields, account relationships and composite uniqueness remain enforced

#### Scenario: A direct context create cannot resolve the expected game

- **WHEN** the resolver returns a failure for the original string slug or resolves a different BGG identity
- **THEN** the context rejects it with the existing reason without saving another game
- **AND** the HTTP adapter preserves the existing error and redirect semantics

#### Scenario: Detail validation remains separate from favorite identity

- **WHEN** detail and an authenticated favorite save resolve the same original game slug
- **THEN** the save checks resolved BGG identity without the detail visibility or Session policy
- **AND** detail still validates its own Session query and retains its existing session prop including the web-owned channel topic

### Requirement: Favorite HTTP operations preserve browser security

The system SHALL provide session-authenticated, CSRF-protected Inertia PUT and DELETE at the exact same query-free `/favorites/:bgg_id` URL using the existing browser Inertia pipeline. The URL SHALL supply mutation identity. PUT SHALL accept the original `slug` as its source form field and require resolved identity to match the path ID, independently of detail visibility and runtime Sessions. Any submitted `session` SHALL be ignored. DELETE SHALL ignore source slug/Session fields and remove only by authenticated account and path ID, without resolving source context. The former `PUT /games/:slug/favorite` route SHALL NOT remain as an alias. Both actions SHALL return `303` to the supplied `response_to` only after validating it with the existing safe-local-path policy, using the existing safe fallback when invalid or absent. Expected failures SHALL use Inertia `assign_errors`: `authentication` for an unauthenticated caller and `favorite` for unresolvable game or changed binding. Infrastructure exceptions SHALL follow the existing framework error path rather than a favorite-error redirect. These failures SHALL preserve their distinct meanings without the former JSON envelope/status contract. Existing framework CSRF and unexpected-error responses SHALL remain unchanged. The routes SHALL NOT use the module CORS boundary.

#### Scenario: Successful mutation returns to its page

- **WHEN** an authenticated form adds or removes a favorite
- **THEN** the server redirects with 303 to the safe local response target
- **AND** when the return page resolves successfully its Inertia response carries authoritative account membership

#### Scenario: Guest calls either write directly

- **WHEN** an unauthenticated request reaches a favorite mutation
- **THEN** it writes nothing and redirects safely with an authentication form error
- **AND** the returned auth prop identifies the current unauthenticated state

#### Scenario: Return target is unsafe

- **WHEN** a mutation supplies an external or otherwise rejected `response_to`
- **THEN** the response uses the existing safe local fallback
- **AND** the return target never grants game or Session access

#### Scenario: Body identity conflicts with the URL

- **WHEN** a request includes a body or query `bgg_id` different from the URL ID
- **THEN** that field cannot replace the path identity for either method
- **AND** PUT still requires the resolved source game to match the path ID

#### Scenario: Add source resolution fails

- **WHEN** PUT supplies its original string slug and the source resolver returns a failure
- **THEN** the existing favorite error returns through the safe 303 redirect without a write

#### Scenario: Removal contains stale source context

- **WHEN** DELETE supplies a hidden or nonexistent slug and an invalid Session field
- **THEN** removal uses only the authenticated account and path ID
- **AND** no source game or Session lookup is required

#### Scenario: Current CSRF token is required

- **WHEN** the browser submits a favorite form after the CSRF cookie rotates
- **THEN** the existing Inertia configuration sends the current cookie token through `x-csrf-token`
- **AND** missing or invalid CSRF state is rejected without a favorites-specific token reader or stale bootstrap fallback

#### Scenario: Storage raises an infrastructure error

- **WHEN** a database or connection exception prevents a PUT or DELETE mutation
- **THEN** it propagates to the existing Phoenix error boundary and its standard server-error response
- **AND** Favorites does not return an unavailable reason, redirect with a storage form error or claim success

### Requirement: Page projections expose only caller membership

Home entries and resolved detail SHALL include a static `favorite` descriptor containing exactly `bggId`, one query-free `action` at `/favorites/<bggId>`, original source `slug`. The descriptor SHALL always omit `session`, including on detail with a validated Session query and SHALL NOT retain `addAction`/`removeAction`. Membership SHALL be a separate lazy `favorites: number[]` page prop containing all saved BGG IDs for the current account from one account-scoped query. The context read API SHALL be `Favorites.list/1`, returning all current-account `Favorite` entities and `[]` for nil without a compatibility alias. Its query SHALL filter by account without an ordering clause or ID-only selection and SHALL promise no result ordering. PageController SHALL explicitly map those entities to BGG IDs inside each lazy favorites prop; the frontend SHALL continue receiving only numeric membership, not the entities. The membership query SHALL be independent of catalog data; detail responses SHALL still perform normal route and Session validation before rendering. Standard Inertia adapter semantics SHALL filter returned props without a favorites-specific header parser or response branch. Application acceptance SHALL permit redundant catalog/BGG reads and schema callback evaluation when those props are excluded from a partial response. Guests SHALL receive an empty array without an account lookup. Membership read failures SHALL NOT become authoritative empty values. The projection SHALL NOT expose another account's membership, users, counts, or saved metadata.

#### Scenario: One game appears in both home collections

- **WHEN** the same BGG game appears in Playable and Games
- **THEN** both controls derive identical saved state from the same favorites prop
- **AND** the static descriptors contain no separately copied saved flag

#### Scenario: Detail metadata falls back

- **WHEN** a visible local detail uses fallback metadata
- **THEN** its favorite identity still comes from the persisted BGG binding
- **AND** its membership and server-provided action/source context remain usable

#### Scenario: Interest and favorites coexist

- **WHEN** a rendered detail exposes the integrated game-interest contract
- **THEN** its favorite descriptor and account favorites array remain independent of interest membership/counts and playable state
- **AND** a favorite mutation does not submit an interest request or change its count

#### Scenario: Another account owns a favorite

- **WHEN** the current account's favorites prop is loaded
- **THEN** only that account's saved BGG IDs appear, even for games absent from the rendered catalog
- **AND** another account's saved IDs are not exposed

### Requirement: Parent button CSS owns favorite star paint

Home and detail favorite controls SHALL retain one unchanged SVG path for both membership states. The parent favorite button's CSS SHALL provide gold `stroke` and `fill: none` for absent membership; its existing saved-state selector SHALL change only the fill to the same gold color. The SVG and path SHALL inherit paint without hard-coded or conditional paint attributes, inline paint styles, icon swaps, new paint props, or runtime paint logic. Both states SHALL retain the same flat gold outline, color, and opacity, without shadows or glow. Server-confirmed membership SHALL select the resting filled state. For Home and detail controls, CSS hover on hover-capable devices and keyboard focus-visible SHALL temporarily fill the star gold without changing membership or aria-pressed. Leaving both states SHALL restore the confirmed empty/filled interior; saved stars SHALL remain filled. Pending and error SHALL retain confirmed membership.

#### Scenario: Absent membership is rendered

- **WHEN** a Home or detail favorite is absent from the current server membership prop and is outside the icon hover/focus preview
- **THEN** its existing SVG displays a gold outline and transparent interior through inherited parent CSS
- **AND** its accessible action and pressed state continue to identify an unsaved favorite

#### Scenario: Confirmed membership changes

- **WHEN** refreshed server props add or remove the game from favorites
- **THEN** the parent saved-state selector changes the same SVG's fill between gold and none while retaining its gold outline
- **AND** no SVG replacement, conditional paint attribute, inline paint style, or JS paint mutation is required

#### Scenario: Interaction has not confirmed a membership change

- **WHEN** a control is hovered, focused, pending, or its request fails before fresh membership is confirmed
- **THEN** its resting star retains the latest confirmed empty/filled interior and outline, with the existing temporary gold fill allowed during hover/focus preview
- **AND** focus, local Form processing semantics, same-control retry and form behavior remain intact without result notifications

### Requirement: Inertia forms own confirmation and authentication

The client SHALL submit explicit PUT/DELETE operations to the same `favorite.action` through a reusable Inertia `<Form>`. PUT SHALL include `slug` and `response_to`; DELETE SHALL include only `response_to`. Neither method SHALL submit a runtime Session field. A Session query in the safe response target SHALL remain navigation context only. Neither method SHALL submit a redundant hidden `bgg_id`. Both SHALL use `only: ["favorites", "auth", "errors"]`, preserved page state, and preserved scroll. Server favorites props SHALL be the sole saved-state authority for every control. Each form SHALL use only its own `processing` snippet state for pending behavior. The client SHALL remove `FavoriteFeedback`, the `favorites_feedback.svelte` renderer, `feedback`/`feedbackId` props and bindings, page-owned pending/result objects and result-based `aria-describedby`. It SHALL NOT provide shared pending coordination, a replacement store/context, success/error notifications or custom HTTP/network notification handlers. Standard Inertia behavior SHALL govern HTTP/network failures. Local processing SHALL drive busy/disabled semantics and prevent repeat activation of that button while retaining keyboard focus through `aria-disabled` rather than native `disabled`. The client SHALL NOT retain a separate membership store, manual fetch/CSRF transport, abort controller, generation/reset/disposal protocol, or retry registry. Guests and expired sessions SHALL use the existing account dialog and safe return path without storing, queuing, merging, or automatically replaying a favorite.

#### Scenario: Confirmed membership preserves the action URL

- **WHEN** confirmed membership changes an Add control to Remove or back
- **THEN** its form action remains the exact same query-free `/favorites/<bggId>` URL
- **AND** the method changes between PUT and DELETE while the safe response target and selective-prop options remain intact
- **AND** the original slug remains in the descriptor for PUT without runtime Session data, while DELETE submits only the response target

#### Scenario: The submitting button is activated again

- **WHEN** a favorite form is processing and its own button is activated again
- **THEN** that activation does not submit another request
- **AND** the button keeps keyboard focus and exposes busy/disabled semantics while retaining confirmed membership

#### Scenario: Another occurrence or game is activated while saving

- **WHEN** one favorite form is processing and another form's control is activated
- **THEN** no favorites-owned shared pending guard blocks the second form, and standard Inertia request behavior applies
- **AND** only each form's own processing state controls its busy availability while all occurrences retain server-confirmed membership

#### Scenario: Response is lost after a successful write

- **WHEN** the client has not received fresh membership props and the user retries through the same favorite control
- **THEN** the current explicit PUT or DELETE is submitted safely again
- **AND** no replay registry or dedicated retry action is required

#### Scenario: Expected failure is returned

- **WHEN** the redirected Inertia response contains a favorite error
- **THEN** the client retains the latest server-confirmed membership and allows another explicit form submission after local processing ends
- **AND** it renders no custom favorite alert, status message or success announcement and does not overwrite props with a local success value

#### Scenario: Navigation overtakes a request

- **WHEN** a new page or authenticated identity is loaded during a favorite request
- **THEN** saved state follows Inertia's current server page props and request lifecycle
- **AND** no favorites-specific reset effect or late JSON response handler can overwrite it

#### Scenario: Guest signs in

- **WHEN** a guest activates a favorite control and completes authentication
- **THEN** the existing safe return flow restores the page with the account's actual membership
- **AND** another explicit activation is required to change it

#### Scenario: Session expires before submission

- **WHEN** the server no longer recognizes the account that the rendered page considered authenticated
- **THEN** the form receives an authentication error through a safe redirect with refreshed auth and favorites props
- **AND** it opens the existing dialog without automatically replaying the operation

#### Scenario: Guest dismisses authentication

- **WHEN** the guest closes the dialog
- **THEN** no favorite is saved and the page remains available

### Requirement: Card favorites omit tooltips and enlarged targets

The single icon-only control on Home and detail SHALL remain a native button with the same bounds as its rendered SVG box and no extra target padding or minimum size. It SHALL retain its accessible name, keyboard focus indicator, Enter/Space activation, confirmed pressed state and shared form behavior without rendering a tooltip or popover. On discovery cards, that square SHALL equal the first title line box height and share its horizontal centerline for single-line and wrapped titles. The detail control SHALL use the same base icon styling without a visible label, text-button box or variant-specific styling.

#### Scenario: A card favorite is hovered or focused

- **WHEN** the pointer or keyboard focus enters the icon button
- **THEN** no tooltip appears and the button continues to expose its action and confirmed state
- **AND** activating the button submits the existing favorite form

#### Scenario: Hover preview ends without saving

- **WHEN** an unsaved icon is hovered or keyboard-focused and then leaves both states
- **THEN** its temporary gold fill returns to an empty interior without a request or membership change
- **AND** a saved icon remains filled throughout the same interaction

#### Scenario: A card title wraps to additional lines

- **WHEN** a compact/Playable or hero card title occupies one or more lines
- **THEN** the favorite button and SVG square have the height of its first line box and share that line box's horizontal centerline
- **AND** additional lines do not shift the icon down or change title typography, card padding or footer layout

### Requirement: Favorites notifications remain deferred

Favorite mutations SHALL NOT render success/error notification UI, a favorite live result region, or a result ID association on Home or detail. The existing authentication dialog and authentication-error behavior SHALL remain intact. Backend favorite error contracts and requested error props SHALL remain unchanged. The client SHALL use standard adapter HTTP/network failure behavior without replacement notification callbacks.

#### Scenario: A favorite response succeeds

- **WHEN** refreshed favorites props confirm an add or removal
- **THEN** every occurrence updates its confirmed pressed state and action
- **AND** no favorite notification or result region is rendered

#### Scenario: A request fails outside expected favorite errors

- **WHEN** a favorite request encounters an HTTP or network failure
- **THEN** the standard Inertia adapter behavior applies without a favorite-specific notification handler
- **AND** confirmed membership remains authoritative and the same control can retry after processing ends

### Requirement: Favorite action messages belong directly to the view

FavoriteButton SHALL declare its complete accessible action messages directly in markup `aria-label`, without script `$derived` action/label values or assembled sentence fragments. With a nonempty optional title, the messages SHALL be `Add ${title} to favorites` and `Remove ${title} from favorites`; otherwise they SHALL be `Add to favorites` and `Remove from favorites`. Confirmed saved state SHALL select the message. The button SHALL render only its existing accessibility-hidden star with no visible Add/Remove or Saving/Removing label. Processing SHALL preserve the accessible action and expose `aria-busy`/`aria-disabled` while preventing repeat activation and retaining focus. The resource descriptor `favorite.action` and Form request contract SHALL remain unchanged.

#### Scenario: Detail has a title

- **WHEN** detail supplies its existing game name to FavoriteButton
- **THEN** the icon-only button has the complete title-aware Add or Remove accessible action without visible label text
- **AND** no presentation variant is required

#### Scenario: A title is unavailable

- **WHEN** title is omitted, null or empty
- **THEN** the button uses the complete generic Add or Remove accessible action without an empty title fragment

#### Scenario: A favorite request is processing

- **WHEN** the existing form submits an add or removal
- **THEN** its accessible action remains based on confirmed saved state and aria-busy/aria-disabled reflect local processing
- **AND** no Saving/Removing text appears, focus stays on the button and repeated activation is prevented
- **AND** confirmed membership, authentication and failure/retry follow the unchanged form contract

### Requirement: Favorite authorization uses current page authentication

FavoriteButton SHALL read `page.props.auth.authenticated` directly inside beforeSubmit on every activation that reaches form submission. It SHALL NOT receive authentication as a component prop, capture or derive an auth boolean/object, introduce a replacement auth store/provider, or supply an absent-auth fallback. Home, GameCollection, GameCard and detail SHALL NOT forward authenticated values for favorites. Independent activation-form authentication SHALL remain unchanged. A guest SHALL open the existing auth dialog without a request; a signed-in page SHALL allow the existing form flow. Authentication-error responses SHALL retain the existing dialog and never replay a mutation automatically. Saved state SHALL remain supplied by confirmed membership props independently of this auth read.

#### Scenario: Page authentication changes on the mounted control

- **WHEN** one mounted favorite begins as guest, its page auth becomes authenticated, and later becomes guest again without rerendering authenticated component props
- **THEN** the initial and final guest activations open the auth dialog without a write and the authenticated activation can submit normally
- **AND** each attempt uses the current page auth value, without automatic replay or stale captured state

#### Scenario: Server authentication has expired

- **WHEN** page auth permits a request but its response reports an authentication error
- **THEN** the existing error callback opens the auth dialog and preserves confirmed membership
- **AND** later activations read refreshed page auth while request methods/fields, retry and focus behavior remain unchanged

#### Scenario: Isolated verification supplies authentication

- **WHEN** an existing test or isolated card/collection story requires guest or authenticated behavior
- **THEN** it sets the actual mocked page auth through existing setPage/set APIs instead of component authenticated args
- **AND** isolated story context is initialized and reset so authentication does not leak across examples
