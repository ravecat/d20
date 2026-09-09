# home-game-discovery Specification

## Purpose
Define how the home page separates launchable persisted games from bounded server-selected browse groups and presents them through responsive, accessible, auto-advancing carousels.
## Requirements
### Requirement: Home conditionally separates playable and browse collections
The home page SHALL preserve a maximum content width of 46.25rem. It SHALL render the non-empty playable collection in a section labelled `Playable` and SHALL render non-empty browse games in a section labelled `Games`. It SHALL omit the complete corresponding section, including its heading, placeholder copy, carousel, and status or control affordances, when a collection is empty. When both sections render, `Playable` SHALL appear before `Games`. Each visible section label SHALL remain a semantic heading at the inline start of its decorative divider, and both dividers SHALL retain the same muted regular-weight tertiary treatment and crisp one-pixel rule.

#### Scenario: Home renders both collections
- **WHEN** playable games and browse games are both non-empty
- **THEN** `Playable` appears before `Games`
- **AND** both labels remain semantic headings with matching muted divider treatment
- **AND** all content remains within the 46.25rem maximum-width shell

#### Scenario: Playable collection is empty
- **WHEN** the home response contains no playable games
- **THEN** no `Playable` section, placeholder, or carousel presentation is rendered
- **AND** a non-empty `Games` section remains available

#### Scenario: Browse collection is empty
- **WHEN** the home response contains no browse game
- **THEN** no `Games` section, placeholder, or carousel presentation is rendered
- **AND** a non-empty `Playable` section remains available

#### Scenario: Both collections are empty
- **WHEN** the home response contains no playable game and no browse game
- **THEN** neither collection section is rendered
- **AND** no empty-state placeholder or carousel affordance is rendered

#### Scenario: Home is viewed at a supported narrow viewport
- **WHEN** the viewport is narrower than the wide home layout
- **THEN** each rendered section adapts within the available inline space
- **AND** no rendered section causes page-level inline overflow

#### Scenario: Image blocks use tighter spacing
- **WHEN** the home page renders adjacent cards and carousel rows
- **THEN** compact-card gutters and the hero-to-compact gap are 0.5rem
- **AND** section separation and heading-to-card spacing are approximately 0.6667rem
- **AND** image-block spacing is approximately two thirds of the previous spacing

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

### Requirement: Playable games use a compact auto-advancing strip
The `Playable` section SHALL render its games as a strip of compact landscape cards whose proportions and responsive sizing match the compact Games row. When more than one playable game exists, the strip SHALL advance one slide after an approximately five-second dwell and loop continuously using only a CSS animation. It SHALL preserve server order and SHALL NOT filter or reorder games.

#### Scenario: Multiple playable games render
- **WHEN** at least two playable games are delivered
- **THEN** they render in server order as compact landscape slides
- **AND** the CSS animation advances one slide per dwell and loops continuously

#### Scenario: Playable dwell completes
- **WHEN** Playable is running and a dwell completes
- **THEN** the next playable slide is settled by the CSS animation
- **AND** a short eased slide movement visibly interpolates between the two positions rather than jumping instantly
- **AND** no script timer participates

#### Scenario: Playable renders with application styles
- **WHEN** Storybook or the application loads daisyUI alongside the home styles
- **THEN** the Playable viewport retains the full available inline width and visibly renders its cards
- **AND** one-, two-, and three-game strips do not collapse or expose a blank gap during looping

#### Scenario: Playable wraps after the final game
- **WHEN** the final playable game is settled and another dwell completes
- **THEN** the first playable game is settled again
- **AND** the wrap exposes no duplicate accessible link and no blank gap

#### Scenario: One playable game is delivered
- **WHEN** exactly one playable game is delivered
- **THEN** it renders as one static compact landscape card
- **AND** no animation, loop sentinel, Previous, Next, Play, or Pause affordance is rendered

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

### Requirement: Carousel behavior is owned entirely by CSS
CSS SHALL own the responsive hero and compact card geometry, the approximate Games row ratio, overflow containment, dwell duration and step count, continuous looping, seamless wrap, pause state, transition presentation, and reduced-motion overrides. Carousel advancement SHALL use CSS keyframes with stepped timing over a track whose slide count is provided as a custom property. Derived-value types SHALL be inferred from typed inputs and computations without redundant annotations or comments explaining the derivation. All card markup SHALL be inline in the rendering loops, without card snippets. Svelte SHALL NOT add carousel state, timers, listeners, observers, selected-index synchronization, manual-scroll reconciliation, document-visibility tracking, dynamic ARIA status, or scripted navigation controls; it MAY render conditional sections, the lossless presentation sequence, the slide-count custom property, and duplicated inert tracks. The primary production path MUST NOT depend on `::scroll-button()`, CSS anchor positioning, scroll snap events, container scroll-state queries, or scroll-driven animations.

#### Scenario: Carousel advances without script
- **WHEN** a multi-item carousel is rendered and its dwell elapses
- **THEN** the next slide is settled by the CSS animation alone
- **AND** no timer, listener, or observer participates in the advancement

#### Scenario: Viewport changes
- **WHEN** the home page moves between supported desktop, tablet, and mobile widths
- **THEN** CSS adapts hero and compact geometry within the shell
- **AND** dwell duration and step count remain derived from the slide count
- **AND** no page-level inline overflow occurs

#### Scenario: Experimental features are unavailable
- **WHEN** a current target lacks generated scroll buttons, anchor positioning, scroll snap events, scroll-state queries, or scroll-driven animations
- **THEN** every carousel remains advancing, looping, pausable, and linked through the baseline path

#### Scenario: Visual loop duplicate is present
- **WHEN** CSS looping uses a duplicated visual track for seamless wrap and focus runway
- **THEN** the duplicate is inert and hidden from the accessibility tree
- **AND** it contains no accessible link or control

### Requirement: Auto-advancing carousels pause on hover and focus
Each rendered carousel with more than one logical item SHALL pause its CSS animation while a pointer hovers within its section or keyboard focus is within its section, and SHALL resume from the held position when the reason leaves. Pausing the Games section SHALL pause both rows together so they cannot drift apart. Pause and resume SHALL be expressed only through CSS state such as `animation-play-state`; the implementation MUST NOT claim persistent Pause, Play controls, manual-stop persistence, or document-hidden pausing that CSS cannot provide, and MUST NOT introduce script to provide them.

#### Scenario: Pointer hovers a running carousel
- **WHEN** pointer hover enters a running carousel section
- **THEN** its animation pauses at the current slide
- **AND** it resumes from that slide after hover leaves

#### Scenario: Focus enters a running carousel
- **WHEN** keyboard focus enters a canonical link in a running carousel section
- **THEN** its animation pauses without moving focus
- **AND** it resumes from the held slide after focus leaves the section

#### Scenario: Games rows pause together
- **WHEN** a pause reason applies to the Games section
- **THEN** both the hero and compact animations are paused
- **AND** both resume together with matched timing

#### Scenario: Reduced motion is requested
- **WHEN** `prefers-reduced-motion: reduce` is active
- **THEN** carousel animation is removed and leading slides render statically
- **AND** non-essential card transitions are removed
- **AND** no opt-in autoplay is reintroduced

#### Scenario: Item count changes between responses
- **WHEN** a rendered collection's logical item count changes across full home responses
- **THEN** the new response renders the correct slide count and animation timing
- **AND** no stale index, timer, or binding survives from the previous response

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

### Requirement: Compact carousel rows center their middle visible card
Each multi-item compact row in Playable and the lower Games carousel SHALL align the middle visible card's center with its own viewport's center at every unfocused settled position. The initial middle card SHALL be the second entry in the delivered sequence. The neighboring cards SHALL remain partially visible with equal clipping at the left and right viewport boundaries. CSS SHALL derive this composition from the existing responsive container and card geometry, retain it for the unfocused reduced-motion presentation, and preserve continuous looping without blank gaps, including two-item collections. Hero and singleton geometry SHALL remain unchanged. Focus SHALL temporarily clear compact alignment as needed to reveal canonical links and SHALL restore the centered composition when focus leaves. Additional loop coverage SHALL remain inert and hidden from the accessibility tree.

#### Scenario: Both compact rows render
- **WHEN** Playable and Games each contain multiple entries at a supported desktop, tablet, or mobile width
- **THEN** the initial middle visible card in each compact row is centered within that row's viewport
- **AND** the neighboring cards are clipped symmetrically at its boundaries
- **AND** the Games hero retains its existing geometry

#### Scenario: Centered compact tracks advance and wrap
- **WHEN** a multi-item compact carousel advances through a complete loop, including a two-item collection
- **THEN** each settled middle card is centered and no blank gap appears during advancement or wrap
- **AND** server order, the shared carousel cadence, synchronized Games rows, and accessible link uniqueness are preserved

#### Scenario: Reduced motion keeps the centered composition
- **WHEN** reduced motion is requested and neither section contains keyboard focus
- **THEN** both multi-item compact rows show a centered static middle card with symmetrically clipped neighbors
- **AND** no animation is introduced

#### Scenario: Keyboard focus reveals the first canonical card
- **WHEN** focus enters a canonical link in a centered carousel section
- **THEN** the focused link and its focus outline are revealed through the existing CSS focus behavior
- **AND** leaving the section restores compact centering and the held animation position

#### Scenario: A section contains one entry
- **WHEN** a collection contains exactly one entry
- **THEN** its static card geometry remains unchanged and no loop copy is added

### Requirement: Home carousel movement uses a soft shared cadence
Every animated home carousel row SHALL hold its settled slide stationary for 5 seconds, then move one slide over 1.1 seconds with CSS `ease-in-out` interpolation. The total step cycle SHALL be 6.1 seconds. The stepped loop displacement and interpolated movement SHALL use the same cycle so advancement and wrap remain continuous. The Playable row and both Games rows SHALL use this cadence, and the Games rows SHALL remain synchronized. Existing hover and focus pause, focus reveal, reduced-motion behavior, singleton presentation, centering, and inert loop-copy accessibility SHALL remain intact.

#### Scenario: A running row advances
- **WHEN** a multi-item home row runs without a pause reason or reduced-motion preference
- **THEN** its card remains stationary for 5 seconds before the next 1.1-second movement
- **AND** the movement accelerates and decelerates through `ease-in-out` before settling one slide later
- **AND** the next cycle begins without a jump or blank gap

#### Scenario: Games rows move together
- **WHEN** the Games hero and compact rows advance or resume after a shared pause
- **THEN** both use the same 6.1-second cadence and transition progress
- **AND** the settled compact card remains centered with equally clipped neighbors

#### Scenario: Motion is paused or disabled
- **WHEN** hover or focus pauses a section, reduced motion is active, or a section contains a singleton
- **THEN** the existing pause, focus reveal, or static behavior is preserved
- **AND** the timing change introduces no script timer, animation library, or new control
