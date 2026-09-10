# game-detail-activation-layout Specification

## Purpose
TBD - created by archiving change redesign-game-detail-activation-layout. Update Purpose after archive.
## Requirements
### Requirement: Game detail content uses a 40/60 activation layout
The system SHALL render the game detail content below the preview as a split layout on viewports that can support two columns. The left panel SHALL contain activation controls and the right panel SHALL contain the game description. The description panel SHALL size to its full content and participate in document scrolling without an independent vertical scroll area.

#### Scenario: Wide viewport renders split panels
- **WHEN** a user opens `/games/qwinto` on a viewport wide enough for the desktop detail layout
- **THEN** the content below the preview is arranged in two columns
- **AND** the activation panel uses 40 percent of the available content width
- **AND** the description panel uses 60 percent of the available content width

#### Scenario: Long description extends the game page
- **WHEN** the runtime game metadata includes a description longer than the available viewport height
- **THEN** the description panel expands to contain the complete description
- **AND** the user reaches its final text by scrolling the document
- **AND** the description panel has no independent vertical scroll area
- **AND** the activation panel remains beside the description in the desktop layout and scrolls with the document

#### Scenario: Split panels have no surrounding borders
- **WHEN** the activation and description panels render below the preview
- **THEN** neither panel draws a surrounding border

#### Scenario: Narrow viewport stacks panels
- **WHEN** a user opens the game detail page on a viewport too narrow for the desktop split
- **THEN** the description panel and activation panel stack in a single column
- **AND** text, controls, icons, and joined-player entries do not overlap
- **AND** the description retains its full content height within the document flow

### Requirement: Activation panel presents game metadata from the API
The system SHALL present player count, play-time, age, complexity, and rating metadata at the top of the activation panel using values from the game metadata API props.

Each metadata label SHALL be rendered by a dedicated Svelte component that receives the game metadata object and owns the formatting helper used for its displayed value.

#### Scenario: Player range is available
- **WHEN** the game metadata includes `minPlayers` `2` and `maxPlayers` `6`
- **THEN** the activation panel presents a users icon with the player range `2-6`
- **AND** the value is derived from the game metadata props

#### Scenario: Single player count is available
- **WHEN** the game metadata includes `minPlayers` `1` and `maxPlayers` `1`
- **THEN** the activation panel presents a users icon with a single player count value
- **AND** the activation panel does not render the range as `1-1`

#### Scenario: Play-time range is available
- **WHEN** the game metadata includes `minPlayTime` `20` and `maxPlayTime` `40`
- **THEN** the activation panel presents a clock icon with the play-time range `20-40`
- **AND** the value is derived from the game metadata props

#### Scenario: Single play time is available
- **WHEN** the game metadata includes `playingTime` `15` and does not include a distinct play-time range
- **THEN** the activation panel presents a clock icon with `15`

#### Scenario: Minimum-only play time is available
- **WHEN** the game metadata includes `minPlayTime` `20` without a `maxPlayTime`
- **THEN** the activation panel presents a clock icon with `20+`

#### Scenario: Minimum age is available
- **WHEN** the game metadata includes `minAge` `8`
- **THEN** the activation panel presents an age icon with `8+`
- **AND** the value is derived from the game metadata props

#### Scenario: Complexity is available
- **WHEN** the game metadata includes `complexity` `2.14`
- **THEN** the activation panel presents a complexity icon with `2.1/5`
- **AND** the value is derived from the game metadata props

#### Scenario: BGG rating is available
- **WHEN** the game metadata includes `rating` `7.42`
- **THEN** the activation panel presents a star icon with `7.4/10`
- **AND** the value is derived from the game metadata props

#### Scenario: Metadata values are missing
- **WHEN** player count, play-time, age, complexity, or rating values are not available from the game metadata props
- **THEN** the activation panel does not render labels for the missing metadata values
- **AND** the system does not display hardcoded game-specific values or placeholder labels

#### Scenario: Only one metadata value is missing
- **WHEN** player count is available from the game metadata props but play-time values are not available
- **THEN** the activation panel presents the player count metadata
- **AND** the activation panel does not render a play-time label or placeholder

#### Scenario: Metadata infographic is visually enlarged
- **WHEN** the activation panel renders player count and play-time metadata
- **THEN** the users and clock metadata treatments render at 1.125 times the original icon and text scale
- **AND** the metadata labels render as chips

### Requirement: Activation CTA reflects the session state
The activation panel SHALL select the existing `Lobby` when a validated Session descriptor exists, otherwise `SessionForm` and `Play` when playable is true and a schema exists, otherwise `InterestForm` only when playable is false. The existing `LaunchForm` / `launch_form.svelte` SHALL be renamed to `SessionForm` / `session_form.svelte`, preserving its Session creation behavior without a compatibility alias. The alternative submission form SHALL be named `InterestForm` in `interest_form.svelte`. Both form files SHALL reside in `assets/js/pages/game/ui/`. `InterestForm` SHALL initially show one visible button named `I want this game!` with the request count and a decorative five-point star before its label, the count available as an accessible description, and the existing full-width primary treatment, and SHALL NOT include game setup fields or instantiate `BasicForm`. Session descriptor, store ownership, permissions, errors, and Workspace/module behavior SHALL remain unchanged.

#### Scenario: No session renders Play
- **WHEN** a user opens playable `/games/qwinto` without a Session and with a creation schema
- **THEN** the activation panel renders `SessionForm` with CTA label `Play`
- **AND** activating it posts the game-owned creation attributes to `/games/qwinto/sessions`
- **AND** the CTA stretches across the available activation panel width

#### Scenario: Existing session renders existing SessionPanel
- **WHEN** the page has a validated Session descriptor
- **THEN** the activation panel renders its existing `Lobby` using the existing session descriptor
- **AND** it renders neither `SessionForm` nor `InterestForm`

#### Scenario: Waiting session behavior remains owned by SessionPanel
- **WHEN** the existing Lobby renders a waiting Session
- **THEN** session start permissions, processing state, errors, and joined-player presence remain owned by the current Session store and Lobby
- **AND** its existing start action retains the current primary treatment

#### Scenario: In-progress session behavior remains owned by SessionPanel
- **WHEN** the existing Lobby observes an in-progress Session
- **THEN** the existing Workspace and module behavior remains unchanged without an additional page-level module wrapper

#### Scenario: Non-playable page renders interest without setup
- **WHEN** a resolved detail has playable false and no Session
- **THEN** the activation panel renders `InterestForm` with `I want this game!` or saved-interest state and the existing full-width CTA treatment
- **AND** metadata remains visible without `SessionForm`, game setup inputs, or Play action

#### Scenario: Interest is reachable with a keyboard and narrow viewport
- **WHEN** a user navigates the activation panel by keyboard or opens it at a supported narrow viewport
- **THEN** the interest action, focus indication, pending and saved button labels, and any error alert remain perceivable and usable without overlapping metadata or description

### Requirement: Activation panel includes joined players
The system SHALL keep joined-player rendering owned by the existing `SessionPanel` while placing that panel inside the activation column.

#### Scenario: Waiting session has joined players
- **WHEN** the waiting session includes members with display names and avatars
- **THEN** `SessionPanel` renders those players in its joined-player area
- **AND** the joined-player area exposes an accessible name for joined players
- **AND** the joined-player area does not draw a surrounding border

#### Scenario: Player avatar is missing
- **WHEN** a joined session member does not include an avatar
- **THEN** `SessionPanel` renders a stable fallback avatar for that member

#### Scenario: Presence is loading or unavailable
- **WHEN** joined-player presence is loading
- **THEN** `SessionPanel` renders its loading state
- **WHEN** joined-player presence is unavailable and no members are visible
- **THEN** `SessionPanel` does not render a presence-unavailable error message

### Requirement: Existing game page contracts are preserved
The system SHALL preserve existing route, session, module, and `SessionPanel` contracts while changing the visual composition of the game detail page.

#### Scenario: Detail route remains slug-based
- **WHEN** a user opens a registered game detail page
- **THEN** the route remains `/games/:slug`

#### Scenario: Session creation route is unchanged
- **WHEN** the activation CTA creates a session for `qwinto`
- **THEN** the request target remains `/games/qwinto/sessions`

#### Scenario: Module connection props are unchanged
- **WHEN** a session has module connection data
- **THEN** the page passes the existing module and connection props to the module frame

#### Scenario: SessionPanel public props are unchanged
- **WHEN** the game page renders `SessionPanel`
- **THEN** it passes only the existing `module` and `connection` props
