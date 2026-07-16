## ADDED Requirements

### Requirement: Shared Objectives are selected and visible when enabled
The system SHALL select exactly 2 distinct Shared Objectives from the fixed set of 5 during first-round preparation when the top-level `objectives` field is enabled and SHALL select none when it is disabled.

#### Scenario: Shared Objectives are enabled
- **WHEN** the system prepares round 1 with Shared Objectives enabled
- **THEN** it commits exactly 2 unique objective ids
- **AND** both objectives remain visible to every caller for all four rounds

#### Scenario: Shared Objectives are disabled
- **WHEN** the system prepares round 1 with Shared Objectives disabled
- **THEN** no Shared Objective is selected or scored

#### Scenario: Shared Objective setup is invalid
- **WHEN** system preparation supplies a duplicate, unknown, wrong-count, or disabled objective assignment
- **THEN** preparation is rejected with `invalid_system_setup`

### Requirement: Five exact Shared Objectives score at game end
The system SHALL define the five whole-network objectives below and award 10 points for each selected objective that a player achieves.

#### Scenario: Eight interchange objective is evaluated
- **WHEN** a selected objective requires interchanges
- **THEN** it is achieved only when the player's network contains at least 8 distinct stations used by at least 2 colored lines

#### Scenario: All districts objective is evaluated
- **WHEN** a selected objective requires all districts
- **THEN** it is achieved only when the player's network contains at least one station in each of all 13 districts

#### Scenario: All tourist sites objective is evaluated
- **WHEN** a selected objective requires tourist sites
- **THEN** it is achieved only when the player's network contains all 5 tourist stations

#### Scenario: Central district objective is evaluated
- **WHEN** a selected objective requires the central district
- **THEN** it is achieved only when the player's network contains all 9 stations assigned to `central`

#### Scenario: Six Thames crossings objective is evaluated
- **WHEN** a selected objective requires Thames crossings
- **THEN** it is achieved only when the player's network uses at least 6 distinct sections flagged as crossing the Thames

#### Scenario: Selected objective is achieved
- **WHEN** final scoring finds that a player satisfies one selected objective
- **THEN** 10 points are added to that player's final score

### Requirement: Pencil Powers form a public color assignment
The system SHALL assign the four distinct Pencil Powers bijectively to green, blue, pink, and purple during first-round preparation when the top-level `powers` field is enabled.

#### Scenario: Pencil Powers are enabled
- **WHEN** the system prepares round 1 with Pencil Powers enabled
- **THEN** each color receives exactly one power
- **AND** each power is assigned exactly once
- **AND** the full color-to-power mapping remains visible to every caller

#### Scenario: Pencil Powers are disabled
- **WHEN** the system prepares round 1 with Pencil Powers disabled
- **THEN** no color receives or can use a power

#### Scenario: Pencil Power setup is invalid
- **WHEN** system preparation supplies a duplicate power, duplicate color, unknown id, incomplete mapping, or mapping while disabled
- **THEN** preparation is rejected with `invalid_system_setup`

### Requirement: A color's Pencil Power is optional and usable once per round
The system SHALL allow only the participant currently holding a color to use that color's assigned power once while building that colored line in the current round.

#### Scenario: Assigned power is used
- **WHEN** a pending participant submits a legal action with the current color's unused assigned power
- **THEN** the action and power effect commit atomically
- **AND** that colored line records the power as used

#### Scenario: Power is reused
- **WHEN** a participant tries to use the same colored line's power again
- **THEN** the action is rejected with `power_already_used`

#### Scenario: Wrong power is submitted
- **WHEN** a participant submits a power not assigned to the current pencil color
- **THEN** the action is rejected with `invalid_power`

#### Scenario: Power is not used
- **WHEN** a participant completes a round without using the assigned power
- **THEN** no fallback effect or score is applied

### Requirement: Double Section draws two same-symbol sections atomically
The `double_section` power SHALL allow exactly two sequential legal sections during one current instruction.

#### Scenario: Ordinary destination uses Double Section
- **WHEN** a participant uses `double_section` on an ordinary destination
- **THEN** both section targets match that same destination symbol or the central wild station
- **AND** the second section is validated against the candidate network after the first section

#### Scenario: Joker destination uses Double Section
- **WHEN** a participant uses `double_section` after a Joker is revealed
- **THEN** the command declares one ordinary `chosen_symbol`
- **AND** both section targets match that chosen symbol or the central wild station

#### Scenario: Effective switch combines with Double Section
- **WHEN** a participant uses `double_section` while the current instruction has an effective Railroad Switch
- **THEN** the first section may originate at any station of the current colored line
- **AND** the second section must originate at a degree-one endpoint of the candidate line after the first section

#### Scenario: One Double Section segment is invalid
- **WHEN** either submitted section violates origin, graph, revisit, duplicate, crossing, destination, or sequence rules
- **THEN** neither section is committed
- **AND** the power remains unused

### Requirement: Joker power changes only destination matching
The `joker` power SHALL treat the current revealed destination as a Joker for one submitted section while preserving every other construction rule.

#### Scenario: Joker power is used
- **WHEN** a participant uses the assigned `joker` power on a non-Joker instruction
- **THEN** the target may have any ordinary symbol or be the central wild station
- **AND** origin, potential edge, revisit, duplicate, and crossing rules still apply

### Requirement: Railroad Switch power changes only allowed origin
The `railroad_switch` power SHALL treat the current destination card as accompanied by a Railroad Switch without consuming another card.

#### Scenario: Railroad Switch power is used
- **WHEN** a participant uses the assigned `railroad_switch` power
- **THEN** the submitted section may originate at any station already on the current colored line
- **AND** its target still matches the already revealed destination or central wild
- **AND** reveal history and remaining deck are unchanged

### Requirement: Double Station changes one line's district maximum only
The `double_station` power SHALL mark one station already on the current colored line and count it twice only for that line's maximum stations-in-one-district factor.

#### Scenario: Double Station is attached to a draw
- **WHEN** a participant submits a valid draw with an eligible double-station target
- **THEN** the section and station mark commit atomically
- **AND** a station reached by the same atomic draw is eligible

#### Scenario: Double Station is attached to a pass
- **WHEN** a participant passes with an eligible double-station target
- **THEN** no section is added
- **AND** the station mark commits
- **AND** the participant becomes submitted

#### Scenario: Double Station target is invalid
- **WHEN** the target station is not already on the current colored line
- **THEN** the action is rejected with `invalid_power_target`
- **AND** no station is marked

#### Scenario: Marked station is scored
- **WHEN** the current colored line is scored
- **THEN** the marked station increases its district's station count by one for the line formula
- **AND** it does not add a tourist mark, interchange line, Shared Objective station, Thames crossing, or credit to any later colored line

### Requirement: Solo rating penalizes enabled advanced modules
The system SHALL subtract 10 points per enabled advanced module from a solo player's score only for achievement-band lookup.

#### Scenario: One advanced module is enabled in solo
- **WHEN** final solo scoring has exactly one of Shared Objectives or Pencil Powers enabled
- **THEN** the rating score is final score minus 10

#### Scenario: Both advanced modules are enabled in solo
- **WHEN** final solo scoring has both modules enabled
- **THEN** the rating score is final score minus 20

#### Scenario: Shared Objective points are earned in solo
- **WHEN** a solo player achieves a selected Shared Objective
- **THEN** its 10 points are included in final score
- **AND** the module penalty is applied afterward for rating-band lookup

#### Scenario: Multiplayer uses advanced modules
- **WHEN** a multiplayer game has either advanced module enabled
- **THEN** no module penalty is subtracted from any final score
