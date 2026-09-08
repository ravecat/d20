## ADDED Requirements

### Requirement: Game visibility is explicit application configuration
The application SHALL configure `:visible_game_stages` as `[:released]` in `config/config.exs` and override it with `[:released, :in_development]` in `config/dev.exs`. Visibility query construction, detail access, and new-Session authorization SHALL read this key directly through `Application.fetch_env!/2`. `Games.list/1` SHALL remain policy-neutral and apply only caller-supplied filters. The application SHALL NOT retain `:d20, :env`, `Games.visible_stages/0`, or compile-time environment flags for this policy.

#### Scenario: Default configuration is resolved
- **WHEN** test or production configuration is loaded without an explicit stage-policy override
- **THEN** the permitted stage list is `[:released]`

#### Scenario: Development configuration is resolved
- **WHEN** development configuration is loaded
- **THEN** the permitted stage list is `[:released, :in_development]`

## MODIFIED Requirements

### Requirement: Every catalog game has a detail page
The system SHALL render metadata details for persisted games whose stages belong to `:visible_game_stages` independently of enabled state or local engine availability. The default configured list SHALL expose only released games; development configuration SHALL include both stages. Application code SHALL read this policy without checking environment identity. Hidden detail pages SHALL return 404. Internal catalog listing and administrative record access SHALL remain policy-neutral. A validated matching existing Session SHALL remain accessible after stage, enabled, or visible-stage configuration edits; a supplied but invalid Session id SHALL NOT bypass visibility.

#### Scenario: In-development detail is opened in development
- **WHEN** the configured stages include in-development and a user opens an in-development game's local detail route
- **THEN** its metadata detail renders even without an engine

#### Scenario: In-development detail is opened in production
- **WHEN** the default released-only policy is configured and a user opens an in-development game's detail without a Session parameter
- **THEN** the response is 404

#### Scenario: Invalid Session is supplied for a hidden game
- **WHEN** an in-development game's detail is requested under the released-only policy with a missing or mismatched Session id
- **THEN** the existing Session-error redirect remains unchanged and exposes no game details
- **AND** following the redirect to the fresh detail route returns 404

#### Scenario: Released disabled detail is opened
- **WHEN** a user requests a disabled released game's detail
- **THEN** the detail remains visible with new-Session launch unavailable

#### Scenario: An active Session outlives publication
- **WHEN** a game's stage changes to in-development after Session creation
- **THEN** a validated matching Session remains accessible through its existing detail workspace
- **AND** new launch remains denied when in-development is absent from the configured list

#### Scenario: Unknown detail is opened
- **WHEN** a user requests a detail route for an unknown game slug
- **THEN** the system returns 404

#### Scenario: Visibility changes after Session creation
- **WHEN** the configured stage list no longer includes a running Session's game stage
- **THEN** the ordinary detail page returns 404
- **AND** the validated matching Session remains accessible through the same detail route with its Session parameter

#### Scenario: No visible stage is configured
- **WHEN** `:visible_game_stages` is empty
- **THEN** home visibility queries return no records and ordinary local detail requests return 404
- **AND** `Games.list/1` still applies only its explicit caller filters
