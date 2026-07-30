# next-station-london-map-data Specification

## Purpose
TBD - created by archiving change implement-next-station-london-rules. Update Purpose after archive.
## Requirements
### Requirement: Publisher rules and map are the static source of truth
The system SHALL encode Next Station: London static rules from the current English Blue Orange rulebook and official Blue Orange map. The system SHALL NOT parse a PDF, inspect artwork, or infer graph data while a game session is running.

#### Scenario: Ruleset is loaded
- **WHEN** the Next Station: London ruleset is loaded
- **THEN** it returns committed Elixir data for the map, cards, advanced modules, and scoring tables
- **AND** no runtime PDF or image operation is required

#### Scenario: Catalog metadata is available
- **WHEN** the ruleset is encoded or reviewed
- **THEN** BoardGameGeek metadata, catalog text, display names, and route slugs are not treated as game-rule sources

### Requirement: London exposes the exact station inventory
The system SHALL expose 53 stations on a stable integer grid using string ids `r<row>c<column>`. `C`, `S`, `T`, `P`, and `W` in the normative inventory mean circle, square, triangle, pentagon, and central wild. `*` means tourist site and a color in parentheses means departure color.

| Row | Stations by column |
| --- | --- |
| 0 | `c0 P`, `c1 T`, `c2 S`, `c4 T`, `c5 C`, `c7 T`, `c9 C` |
| 1 | `c1 P`, `c3 S`, `c6 P*`, `c8 S`, `c9 P` |
| 2 | `c0 C`, `c3 T(green)`, `c6 S`, `c9 T` |
| 3 | `c0 S*`, `c2 P`, `c4 T`, `c5 W*`, `c6 C`, `c7 C(pink)`, `c9 S` |
| 4 | `c1 T`, `c2 S`, `c4 P`, `c5 S`, `c8 P` |
| 5 | `c0 P`, `c2 S(purple)`, `c4 C`, `c7 C` |
| 6 | `c3 P`, `c4 T`, `c6 S`, `c7 T`, `c9 T*` |
| 7 | `c0 C`, `c2 S`, `c3 C`, `c5 P(blue)`, `c8 C`, `c9 P` |
| 8 | `c1 C`, `c6 P`, `c8 T` |
| 9 | `c0 T`, `c1 S`, `c3 P`, `c4 C*`, `c5 T`, `c7 C`, `c9 S` |

#### Scenario: Station inventory is validated
- **WHEN** static map integrity is checked
- **THEN** the map contains exactly 13 circles, 13 squares, 13 triangles, 13 pentagons, and one central wild station
- **AND** every station id, coordinate, and symbol matches the normative inventory

#### Scenario: Tourist sites are queried
- **WHEN** the tourist station ids are requested
- **THEN** the result is exactly `r1c6`, `r3c0`, `r3c5`, `r6c9`, and `r9c4`
- **AND** `r3c5` is both the central wild station and a tourist site

#### Scenario: Departure stations are queried
- **WHEN** departure stations are requested
- **THEN** green starts at triangle `r2c3`
- **AND** pink starts at circle `r3c7`
- **AND** purple starts at square `r5c2`
- **AND** blue starts at pentagon `r7c5`

### Requirement: London exposes 13 exact districts
The system SHALL assign each station to exactly one of 9 main districts or 4 secondary corner districts.

#### Scenario: Main district membership is derived
- **WHEN** a non-corner station is assigned to a district
- **THEN** row bands are `0..2`, `3..6`, and `7..9`
- **AND** column bands are `0..2`, `3..6`, and `7..9`
- **AND** the resulting main district counts are 4 northwest, 6 north, 4 northeast, 6 west, 9 central, 6 east, 4 southwest, 6 south, and 4 southeast

#### Scenario: Secondary districts are derived
- **WHEN** corner district data is requested
- **THEN** `r0c0`, `r0c9`, `r9c0`, and `r9c9` each form a distinct one-station secondary district
- **AND** those stations are excluded from the corresponding main district

#### Scenario: District integrity is invalid
- **WHEN** a station has no district, more than one district, or a district count differs from the normative count
- **THEN** static map validation fails

### Requirement: Potential sections form one exact undirected graph
The system SHALL expose a canonical undirected potential-section graph. From each station, a potential section reaches the first station on each horizontal, vertical, or 45 degree diagonal ray and SHALL NOT pass through an intermediate station.

#### Scenario: Potential graph is validated
- **WHEN** static edge integrity is checked
- **THEN** the graph contains exactly 155 unique undirected sections
- **AND** every endpoint is a known station
- **AND** every edge is canonical, aligned to an allowed ray, and reaches the nearest station on that ray

#### Scenario: Invalid potential section is encoded
- **WHEN** an edge is duplicated, references an unknown station, uses another angle, or skips an intermediate station
- **THEN** static map validation fails

#### Scenario: Geometry is queried
- **WHEN** the engine compares two potential sections
- **THEN** the ruleset exposes sufficient integer endpoint geometry to distinguish no intersection, a shared station endpoint, an empty-grid crossing, and an overlapping edge

### Requirement: Thames crossings are explicit edge facts
The system SHALL flag exactly the potential sections that pass under the Thames rather than estimating river crossings from client coordinates.

#### Scenario: Thames edge set is queried
- **WHEN** all Thames crossing sections are requested
- **THEN** exactly these 24 undirected edges are returned: `r2c0-r4c2`, `r3c0-r5c0`, `r3c0-r4c1`, `r1c1-r4c1`, `r3c2-r4c1`, `r3c2-r4c2`, `r4c2-r4c4`, `r3c4-r5c2`, `r5c2-r5c4`, `r2c3-r6c3`, `r5c4-r6c3`, `r4c4-r6c6`, `r5c4-r6c4`, `r5c4-r5c7`, `r3c7-r6c4`, `r3c5-r5c7`, `r4c5-r7c5`, `r4c5-r6c7`, `r3c6-r6c6`, `r3c6-r6c9`, `r3c7-r5c7`, `r4c8-r5c7`, `r4c8-r7c8`, and `r3c9-r6c9`

#### Scenario: Non-Thames edge is queried
- **WHEN** a potential section is not in the normative Thames edge set
- **THEN** its `crosses_thames` value is false

### Requirement: Station deck is exact and reviewable
The system SHALL expose 11 unique Station cards: one Street and one Underground card for each of circle, square, triangle, and pentagon, one Street Joker, one Underground Joker, and one Street Railroad Switch.

#### Scenario: Full deck is requested
- **WHEN** the Station deck is requested
- **THEN** it contains exactly 6 Street cards and 5 Underground cards
- **AND** it contains two Jokers and one Railroad Switch
- **AND** every card has a stable id, destination kind, and Street or Underground classification

#### Scenario: Round deck permutation is validated
- **WHEN** a prepared round deck is checked
- **THEN** it is accepted only when it contains every static card id exactly once

#### Scenario: Fifth Underground card is detected
- **WHEN** revealed history gains its fifth Underground card
- **THEN** the ruleset identifies that destination instruction as the final instruction of the round

### Requirement: Fixed scoring tables are exposed by Ruleset
The system SHALL expose the tourist, interchange, Shared Objective, solo band, and solo module-penalty values as static ruleset data.

#### Scenario: Tourist score is looked up
- **WHEN** the capped tourist mark count is from 0 through 10
- **THEN** the respective score is `0, 1, 2, 4, 6, 8, 11, 14, 17, 21, 25`

#### Scenario: Interchange score is looked up
- **WHEN** a station belongs to exactly 2, 3, or 4 distinct colored lines
- **THEN** its respective interchange value is 2, 5, or 9

#### Scenario: Shared Objective value is looked up
- **WHEN** an enabled Shared Objective is achieved
- **THEN** its value is 10 points

#### Scenario: Solo rating is looked up
- **WHEN** an adjusted solo score is evaluated
- **THEN** the bands are less than 90, 90 through 105, 106 through 120, 121 through 135, 136 through 150, and greater than 150

#### Scenario: Solo module penalty is looked up
- **WHEN** Shared Objectives or Pencil Powers are enabled in solo mode
- **THEN** each enabled module has a 10 point rating penalty
