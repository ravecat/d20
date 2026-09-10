## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: Game-detail activation states are reviewable in Storybook
Storybook SHALL expose the production game detail page under a route-like `/games/:slug` group using its production wide layout and deterministic mocked transport state. It SHALL include playable detail without a Session, an existing waiting Session, unavailable detail without a Session, and authenticated saved interest. Stories SHALL verify the visible activation state and SHALL NOT open live Session channels or submit real interest requests.

#### Scenario: Detail activation variants are inspected
- **WHEN** a developer opens the game-detail stories
- **THEN** the no-Session playable story shows Play, the waiting-Session story shows Lobby, the unavailable story shows I want this game!, and the saved-interest story shows disabled Requested without a separate success message below the button
- **AND** each story renders game metadata and description inside the production page layout
- **AND** the stories have reviewed desktop, tablet, and mobile screenshot references
