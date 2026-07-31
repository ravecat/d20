## RENAMED Requirements

- FROM: `Workspace layout starts Compact`
- TO: `Workspace layout starts Auto`

## MODIFIED Requirements

### Requirement: Workspace layout starts Auto

Each newly mounted workspace instance SHALL start in Auto layout and SHALL select the first session in the current authoritative workspace snapshot for Theater. Browser-local layout state MUST NOT synchronize presentation state across tabs, windows, browsers, or devices.

#### Scenario: Initial snapshot contains sessions

- **WHEN** a newly mounted workspace receives its first complete snapshot with one or more sessions
- **THEN** the first authoritative session renders as the Theater window
- **AND** every remaining session renders as a Compact status bar

#### Scenario: Auto workspace receives a replacement snapshot

- **WHEN** an Auto workspace receives a replacement authoritative snapshot with one or more sessions
- **THEN** the first session in that snapshot renders as the Theater window
- **AND** every remaining session renders as a Compact status bar

#### Scenario: Player compacts the workspace

- **WHEN** the player activates the Theater window's Compact control
- **THEN** every session renders as a Compact status bar

#### Scenario: Player explicitly restores a session

- **WHEN** the player activates a Compact restore surface
- **THEN** that session becomes the Theater window

#### Scenario: Workspace mounts again

- **WHEN** the workspace component is unmounted and a new instance mounts for the same actor
- **THEN** the new instance starts in Auto independently of the previous instance's layout selection
