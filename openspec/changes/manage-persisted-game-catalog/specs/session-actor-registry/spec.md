## MODIFIED Requirements

### Requirement: Actor Session discovery uses attachment lookup
`D20.Sessions.list/1` SHALL resolve only runtime entries returned by `D20.Sessions.Registry` for the authenticated actor and SHALL return each as `{pid, {session, game_id}}`, where `game_id` is the canonical `game` TypeID captured by that Session process.

#### Scenario: Actor lists attached Sessions
- **WHEN** an actor has two attachments and unrelated Session runtimes also exist
- **THEN** `D20.Sessions.list/1` returns only the two attached runtimes with local game ids
- **AND** does not select every entry from `D20.Registry`

#### Scenario: Registry entry becomes stale during lookup
- **WHEN** an attached Session terminates between Registry lookup and state resolution
- **THEN** `D20.Sessions.list/1` skips the unavailable runtime
- **AND** other attached live runtimes remain in the result

#### Scenario: Scope has no actor
- **WHEN** `D20.Sessions.list/1` receives a scope without an actor
- **THEN** it returns an empty list
