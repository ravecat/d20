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
The `Playable` section SHALL contain only persisted D20 games accepted by authoritative new-Session launch policy. Home SHALL call `Games.list_playable(8)` with an ordinary integer limit. The context SHALL own enabled/stage/engine conditions and released then in-development and local-id ordering. Only the context SHALL consult the deployed engine enum and construct Ecto queries. General catalog listing SHALL remain policy-neutral. The client SHALL NOT derive or filter launch eligibility.

#### Scenario: Mixed catalog is projected
- **WHEN** persisted games include launchable and non-launchable records
- **THEN** `Playable games` includes only launchable records
- **AND** released entries precede in-development entries, ordered by local id within each stage
- **AND** no more than eight records are included

#### Scenario: More than eight games are launchable
- **WHEN** more than eight persisted records pass launch policy
- **THEN** only the first eight in the explicitly requested playable order appear in `Playable games`
- **AND** later launchable records remain eligible for the bounded `Browse games` query

#### Scenario: Launch policy differs by environment
- **WHEN** launch policy denies an in-development game in the current environment
- **THEN** that game does not appear in `Playable games`
- **AND** the client does not independently infer eligibility from stage

#### Scenario: No local game is launchable
- **WHEN** launch policy denies every persisted game
- **THEN** the `Playable` section is omitted
- **AND** no playable-games placeholder is rendered

### Requirement: Browse groups contain the remaining persisted catalog
The server SHALL exclude selected playable ids from the environment-visible catalog and return at most 32 remaining records as a flat `games` array of maps containing id, slug, stage, and game metadata. It SHALL NOT chunk the response or create group ids or envelopes. Every selected game SHALL appear exactly once. The client SHALL consume the array directly in response order without flattening, filtering, shuffling, fetching, or changing membership.

#### Scenario: Remaining catalog is returned
- **WHEN** nineteen environment-visible records remain after playable selection
- **THEN** games contains nineteen catalog-entry maps directly
- **AND** no browseGroups prop or group envelope is returned

#### Scenario: More than 32 records remain
- **WHEN** more than 32 environment-visible records remain after playable selection
- **THEN** games contains exactly 32 catalog-entry maps
- **AND** no selected playable id is included
- **AND** other environment-visible records remain directly detail-addressable

#### Scenario: Few records remain
- **WHEN** between one and fifteen records remain
- **THEN** games contains exactly those records without padding or grouping

#### Scenario: No records remain
- **WHEN** every eligible record was selected as playable
- **THEN** games is empty and the Games section is omitted

#### Scenario: Home is loaded again
- **WHEN** a new full home response is produced
- **THEN** no stable or randomized browse order is guaranteed
- **AND** no carousel position or recommendation history is persisted

#### Scenario: Client prepares slides
- **WHEN** the client receives games
- **THEN** every entry remains in response order without flattening a transport envelope
- **AND** preparing loop copies changes no membership and sends no request

### Requirement: All carousel content is delivered in the initial response
All playable entries and browse games used by the home carousels SHALL be present in the initial Inertia response. Auto-advancement, looping, pausing, duplicated visual tracks, and reduced-motion presentation MUST NOT request another game. Activating a canonical game detail link MAY perform its normal Inertia navigation to `/games/:slug`.

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
The `Games` section SHALL use an Apple “Endless entertainment”-like composition without copying Apple assets or source code. An upper row of large landscape hero cards SHALL occupy roughly two thirds of the carousel presentation, and a lower row of compact landscape cards SHALL occupy roughly one third. Both rows SHALL derive from the same lossless ordered browse sequence, SHALL settle one slide per approximately five-second dwell, SHALL advance together through identical CSS animation duration and step count, and SHALL loop continuously. A pause reason scoped to the section SHALL pause both rows together. The hero row SHALL own exactly one canonical `/games/:slug` detail link for each delivered browse entry, and the compact row SHALL be an inert decorative visual hidden from the accessibility tree.

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
- **THEN** exactly one accessible `/games/:slug` link for that entry exists
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
Each delivered game SHALL expose exactly one semantic canonical `/games/:slug` link with a meaningful accessible name and visible focus. Duplicated loop tracks and the inert compact strip SHALL be absent from the accessibility tree and tab order. A focused canonical link SHALL be revealed inside its carousel viewport by CSS overflow containment and the duplicated inert track, without script involvement. The implementation SHALL NOT provide scripted Previous, Next, Play, or Pause controls or dynamic status announcements, and canonical links SHALL carry their own accessible names.

#### Scenario: Canonical and duplicate content coexist
- **WHEN** a loop boundary renders duplicated content beside canonical content
- **THEN** only canonical links participate in keyboard and accessibility order
- **AND** each delivered game contributes exactly one accessible detail link

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
Every delivered game SHALL retain one canonical D20 `/games/:slug` detail link in its owning section. Runtime metadata SHALL provide display fields when available. Metadata failure SHALL NOT remove a delivered card, alter collection membership or order, require a display name, or create duplicate accessible links. Empty metadata SHALL retain the current linked fallback preview and generic accessible label.

#### Scenario: Playable card is activated
- **WHEN** a user activates a canonical Playable card
- **THEN** navigation targets that persisted game's D20 detail route by persisted slug

#### Scenario: Browse card is activated
- **WHEN** a user activates a canonical Games hero card
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
- **THEN** each delivered game contributes exactly one accessible `/games/:slug` link
- **AND** no duplicate track or repeated visual card contributes a duplicate accessible link

### Requirement: Home tests cover application behavior and visual states
Automated home tests SHALL verify content, local links, metadata fallback, conditional sections, and keyboard accessibility. Presentation SHALL be verified through screenshot comparisons at named UI states and viewports using the screenshotter defaults. Tests SHALL NOT query animation objects or CSS timing properties, manipulate playback or current time, or assert browser interpolation, pause/resume, duration, or looping mechanics.

#### Scenario: Keyboard navigation is verified
- **WHEN** a browser test tabs through the home catalog
- **THEN** each canonical game link receives focus in server order and decorative duplicates do not enter the tab order
- **AND** the test does not seek or inspect a browser animation

#### Scenario: Presentation is verified
- **WHEN** a test captures a home layout, focused card, or reduced-motion state
- **THEN** it compares a screenshot using the screenshotter defaults
- **AND** it does not measure animation timing, playback state, or intermediate motion frames
