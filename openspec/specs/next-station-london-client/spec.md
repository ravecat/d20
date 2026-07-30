# next-station-london-client Specification

## Purpose
TBD - created by archiving change implement-next-station-london-rules. Update Purpose after archive.
## Requirements
### Requirement: The iframe client consumes the caller-specific D20 contract

The Next Station: London iframe client SHALL bootstrap `next-station-london` through the D20 SDK, SHALL replace its state from connect and projection events, and SHALL forward `draw_sections` and `pass` payloads without deriving or weakening server legality.

#### Scenario: A projection arrives

- **WHEN** the D20 shell connects the iframe or publishes an updated caller-specific projection
- **THEN** the client replaces the displayed session, permissions, legal options, networks, scores, and outcome with that projection
- **AND** it does not reconstruct hidden cards, another caller's legal options, or participant order

#### Scenario: A player confirms a route

- **WHEN** the pending caller selects a section or complete Double Section sequence exposed in `options` and confirms it
- **THEN** the client sends `draw_sections` with only the selected section endpoints and applicable power fields
- **AND** rendering coordinates or other client-only data are not included

### Requirement: The client presents every playable session state

The shared D20 shell SHALL present the ordinary owner start control with no game-specific start fields. After the outer session starts, the iframe client SHALL present automatic round and pencil preparation, current and prior instructions, pending route selection, submitted waiting, spectator viewing, four-round progress, scoring, multiplayer outcomes, solo ratings, action errors, and timeouts from the projection and SDK state.

#### Scenario: A solo owner starts through shared session controls

- **WHEN** one joined owner is in the waiting phase
- **THEN** the caller-specific projection omits declarative start-form attributes
- **AND** the shared `SessionPanel` sends an empty `start` payload
- **AND** the iframe remains unmounted until the outer session enters `in_progress`
- **AND** the server assigns the random pencil cycle during automatic round-one preparation

#### Scenario: A submitted player waits

- **WHEN** the caller has submitted the current instruction while another frozen player remains pending
- **THEN** route mutation controls are replaced with a waiting state
- **AND** committed networks and the shared instruction remain visible

#### Scenario: A spectator views the session

- **WHEN** the caller is not a frozen player
- **THEN** the client exposes no mutation controls
- **AND** allows viewing one existing player network without inventing a roster order

### Requirement: Authoritative options drive all construction controls

The client SHALL use `sections`, `joker_sections`, `switch_sections`, `double_sections`, `double_station_targets`, and `double_station_sections` as authoritative interaction options for the current caller.

#### Scenario: Double Station extends the line

- **WHEN** the caller enables Double Station and selects a projected section
- **THEN** the target selector contains only the targets correlated with that section
- **AND** confirmation remains disabled until one correlated target is selected

#### Scenario: Double Station is used while passing

- **WHEN** no section is selected and the caller chooses to spend Double Station while passing
- **THEN** the target selector uses `double_station_targets`
- **AND** the client sends `pass` with the selected power and target

#### Scenario: Double Section is available

- **WHEN** the caller enables Double Section
- **THEN** the client presents each complete projected two-section sequence and its optional chosen symbol
- **AND** sends the selected sequence atomically in one command

### Requirement: The board remains usable across input methods and viewports

The client SHALL render the bundled London board with committed colored lines, doubled stations, current selection, and legal route overlays, and SHALL keep route controls accessible by pointer and keyboard on desktop and mobile layouts.

#### Scenario: A keyboard user selects a legal section

- **WHEN** a legal route overlay receives Enter or Space
- **THEN** the same normalized section is selected as for a pointer click
- **AND** the confirm control reflects the selection

#### Scenario: The board is taller than the desktop viewport

- **WHEN** the board and controls would exceed the available desktop height
- **THEN** the board scales within the available height without clipping its first or final station rows

#### Scenario: The client is shown on a narrow viewport

- **WHEN** the viewport uses the mobile layout
- **THEN** status, board, score, and controls form a readable single-column flow
- **AND** the board remains full-width without horizontal document overflow
