## MODIFIED Requirements

### Requirement: Playable games reflect authoritative launch eligibility
The Playable section SHALL contain only persisted games accepted by authoritative new-Session launch policy. Home SHALL call `Games.list_playable(limit: 8, order_by: [desc: :stage, asc: :id])`. The context SHALL own enabled/stage/engine conditions and consult the deployed engine enum. The controller SHALL select ordering without duplicating launch predicates. General local listing SHALL remain policy-neutral. Provider Games selection SHALL be independent and SHALL NOT exclude playable IDs. The client SHALL NOT derive or filter launch eligibility.

#### Scenario: Mixed local catalog is projected
- **WHEN** local rows include launchable and non-launchable games
- **THEN** Playable includes only launchable games, at most eight, ordered by released then in-development stage and local id

#### Scenario: More than eight games are launchable
- **WHEN** more than eight rows pass launch policy
- **THEN** only the first eight appear in Playable
- **AND** any BGG game remains eligible for independent Hot selection

#### Scenario: Launch policy denies an in-development game
- **WHEN** in-development stage is hidden
- **THEN** that local game is absent from Playable
- **AND** a matching Hot game may remain in Games with null stage and a decimal BGG route slug

#### Scenario: No local game is launchable
- **WHEN** launch policy denies every persisted game
- **THEN** Playable is omitted without a placeholder
- **AND** a non-empty provider Games collection still renders

### Requirement: Games collection comes from BGG Hot
The server SHALL return Games from `Games.list_by_provider()` as a flat array containing up to 32 randomly selected unique Hot games by default. Each entry SHALL contain numeric BGG `id`, non-null internal route `slug` and nullable local `stage`, and runtime `game` metadata. Games SHALL NOT depend on local row existence or exclude selected Playable IDs. There SHALL be no grouping envelope or synthetic IDs. When the provider operation succeeds, every selected provider identity SHALL appear once within Games. The client SHALL preserve server order and membership without filtering, cross-section deduplication, shuffling, or additional fetching.

#### Scenario: Hot contains more than the default limit
- **WHEN** Hot provides more than 32 distinct valid IDs
- **THEN** Games contains 32 selected entries from that pool
- **AND** no playable overlap is removed

#### Scenario: Hot contains fewer games
- **WHEN** Hot contains between one and 31 distinct valid IDs
- **THEN** all available selected identities appear without padding or grouping

#### Scenario: Provider collection is empty or discovery fails
- **WHEN** Hot has no valid IDs or Hot/detail loading returns an error
- **THEN** games is empty and the Games section is omitted
- **AND** a non-empty Playable section remains available

#### Scenario: Local catalog is empty
- **WHEN** Hot returns valid games but persistence contains no games
- **THEN** Games still renders the selected provider entries

#### Scenario: Home is loaded again
- **WHEN** a new full home response is produced
- **THEN** the server may choose another random Hot subset without a guarantee of different membership
- **AND** no recommendation history or carousel position is persisted

#### Scenario: Client prepares slides
- **WHEN** the client receives games
- **THEN** every entry remains in response order and loop copies send no request

### Requirement: All carousel content is delivered in the initial response
All playable entries and browse games used by the home carousels SHALL be present in the initial Inertia response. Auto-advancement, looping, pausing, duplicated visual tracks, and reduced-motion presentation MUST NOT request another game. Activating a canonical game detail link SHALL use normal internal Inertia navigation to `/games/:slug` with the route identifier supplied by the context, including decimal BGG route slugs.

#### Scenario: Autoplay advances
- **WHEN** a carousel dwell completes and the next slide is settled
- **THEN** the carousel uses only the initial response
- **AND** no network request occurs

#### Scenario: Loop wraps at a boundary
- **WHEN** the animation completes its final dwell and restarts
- **THEN** selection continues from the first slide without a visible discontinuity
- **AND** no continuation request occurs

### Requirement: Games uses matched hero and compact carousel rows
The `Games` section SHALL use an Apple “Endless entertainment”-like composition without copying Apple assets or source code. An upper row of large landscape hero cards SHALL occupy roughly two thirds of the carousel presentation, and a lower row of compact landscape cards SHALL occupy roughly one third. Both rows SHALL derive from the same lossless ordered browse sequence, SHALL settle one slide per approximately five-second dwell, SHALL advance together through identical CSS animation duration and step count, and SHALL loop continuously. A pause reason scoped to the section SHALL pause both rows together. The hero row SHALL own exactly one canonical detail link using the server-resolved route slug for each delivered browse entry, and the compact row SHALL be an inert decorative visual hidden from the accessibility tree.

#### Scenario: Games renders at a supported wide viewport
- **WHEN** multiple browse entries are delivered at the supported wide layout
- **THEN** the hero row occupies approximately two thirds of the Games carousel presentation
- **AND** the compact row occupies approximately one third
- **AND** both rows use landscape cards

#### Scenario: Games advances automatically
- **WHEN** Games is running and a dwell completes
- **THEN** both rows settle the next slide of the same sequence together
- **AND** their animation durations and step counts remain matched
- **AND** both rows visibly interpolate through the same eased transition progress before settling

#### Scenario: Games wraps after the final slide
- **WHEN** both rows complete the final dwell of the sequence
- **THEN** both rows continue from the first slide without a visible discontinuity
- **AND** no blank gap or duplicate accessible link appears

#### Scenario: Games has one logical item
- **WHEN** the browse sequence contains exactly one entry
- **THEN** one static hero card is rendered with no animation, loop sentinel, Previous, Next, Play, or Pause affordance
- **AND** no inert compact track is animated

#### Scenario: Hero link is unique
- **WHEN** a browse entry is represented in the hero row, the compact row, and a duplicated loop track
- **THEN** exactly one accessible detail link for that entry exists
- **AND** every other representation is inert and hidden from the accessibility tree

### Requirement: Carousel links and focus remain accessible
Each delivered game SHALL expose exactly one semantic canonical detail link in each owning section using the server-resolved route slug with a meaningful accessible name and visible focus. Duplicated loop tracks and the inert compact strip SHALL be absent from the accessibility tree and tab order. A focused canonical link SHALL be revealed inside its carousel viewport by CSS overflow containment and the duplicated inert track, without script involvement. The implementation SHALL NOT provide scripted Previous, Next, Play, or Pause controls or dynamic status announcements, and canonical links SHALL carry their own accessible names.

#### Scenario: Canonical and duplicate content coexist
- **WHEN** a loop boundary renders duplicated content beside canonical content
- **THEN** only canonical links participate in keyboard and accessibility order
- **AND** each delivered game contributes exactly one accessible detail link in its owning section

#### Scenario: Keyboard focus reaches a canonical link
- **WHEN** a canonical link receives keyboard focus
- **THEN** the link shows visible focus
- **AND** the carousel animation pauses
- **AND** the focused link is revealed within the carousel viewport through CSS containment and the inert duplicate runway

#### Scenario: Focus enters after autoplay has passed the first game
- **WHEN** keyboard focus reaches an earlier canonical link after multiple advances
- **THEN** CSS temporarily neutralizes the paused track displacement so native focus scrolling can reveal that link
- **AND** its focus outline is visible within the card
- **AND** leaving the section clears the temporary focus scroll and resumes the held CSS animation position

#### Scenario: Fallback metadata keeps a meaningful name
- **WHEN** a delivered game has no runtime display name
- **THEN** its canonical link retains a generic accessible name
- **AND** it remains keyboard reachable in server order

### Requirement: Visible cards preserve local identity and metadata fallback
Every delivered game SHALL retain one canonical detail link in its owning section. Every entry SHALL link to D20 `/games/:slug` using the server-resolved non-null route slug. Local and provider-only entries SHALL share the same internal Inertia behavior; the client SHALL NOT choose an external BGG URL, derive a fallback slug, or attach conditional navigation behavior. Client rendering keys and accessible label IDs SHALL use BGG identity rather than requiring a local ID. Runtime metadata SHALL provide display fields when available. Missing or invalid per-item metadata within a successful response SHALL NOT remove a delivered card, alter collection membership or order, require a display name, or create duplicate accessible links. Empty metadata SHALL retain the current linked fallback preview and generic accessible label.

#### Scenario: Playable card is activated
- **WHEN** a user activates a canonical Playable card
- **THEN** navigation targets that persisted game's D20 detail route by persisted slug

#### Scenario: Browse card is activated
- **WHEN** a user activates a canonical Games hero card with a visible local association
- **THEN** navigation targets that persisted game's D20 detail route by persisted slug
- **AND** no carousel transition or catalog record is persisted

#### Scenario: Metadata enrichment fails
- **WHEN** runtime metadata is unavailable for a delivered playable or browse record
- **THEN** the record remains in its server-selected collection and order
- **AND** its fallback card remains linked and keyboard accessible

#### Scenario: Compact metadata is shown on mobile
- **WHEN** a compact card has a long title or multiple categories at a narrow viewport
- **THEN** its title and category row do not overlap
- **AND** visual truncation preserves the full accessible text
- **AND** a narrow inert in-development copy may omit categories to make room for its badge while its canonical hero retains them

#### Scenario: Link uniqueness is inspected
- **WHEN** canonical slides and duplicated visual representations are present
- **THEN** each delivered game contributes exactly one accessible detail link in its owning section
- **AND** no duplicate track or repeated visual card contributes a duplicate accessible link

#### Scenario: Browse entry has no local association
- **WHEN** a delivered Games entry has a positive BGG ID, metadata, a decimal BGG route slug, and null stage
- **THEN** its canonical card opens the internal numeric detail route through Inertia
- **AND** it has neutral lifecycle treatment without an in-development badge
- **AND** its decorative copies expose no additional accessible links

#### Scenario: Provider-only entry has empty display metadata
- **WHEN** a delivered entry has a numeric route slug and empty metadata
- **THEN** its fallback card retains a generic accessible name and its internal numeric detail link
- **AND** the absence of a local ID or display name does not remove the card

### Requirement: Home tests cover application behavior and visual states
Automated home tests SHALL verify content, internal local and numeric links, nullable local stage, metadata fallback, conditional sections, and keyboard accessibility. Presentation SHALL be verified through screenshot comparisons at named UI states and viewports using the screenshotter defaults. Tests SHALL NOT query animation objects or CSS timing properties, manipulate playback or current time, or assert browser interpolation, pause/resume, duration, or looping mechanics.

#### Scenario: Keyboard navigation is verified
- **WHEN** a browser test tabs through the home catalog
- **THEN** each canonical game link receives focus in server order and decorative duplicates do not enter the tab order
- **AND** the test does not seek or inspect a browser animation

#### Scenario: Presentation is verified
- **WHEN** a test captures a home layout, focused card, or reduced-motion state
- **THEN** it compares a screenshot using the screenshotter defaults
- **AND** it does not measure animation timing, playback state, or intermediate motion frames

#### Scenario: One game appears in both sections
- **WHEN** the same BGG ID is delivered in Playable and Games
- **THEN** each section exposes one canonical link for that game
- **AND** their accessible label IDs are distinct across sections and decorative copies add no accessible link
