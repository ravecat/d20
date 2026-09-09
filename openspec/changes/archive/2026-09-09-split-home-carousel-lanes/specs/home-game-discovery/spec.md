## MODIFIED Requirements

### Requirement: Games uses matched hero and compact carousel rows
The `Games` section SHALL retain an Apple “Endless entertainment”-like composition without copying Apple assets or source code. When both lanes render, an upper row of large landscape hero cards SHALL occupy roughly two thirds of the carousel presentation, and a lower row of compact landscape cards SHALL occupy roughly one third. For `n` delivered Games entries, the hero lane SHALL contain the first `ceil(n / 4)` entries and the compact lane SHALL contain the remaining entries, each in server order. Their canonical sequences SHALL be disjoint by BGG identity and their concatenation SHALL reproduce the complete response without filtering, padding, shuffling, additional fetching or cross-request history. Playable overlap SHALL remain permitted. Empty lanes SHALL be omitted. Each non-empty lane SHALL own exactly one canonical internal detail link per assigned entry; additional within-lane loop copies SHALL remain pointer-activatable internal links, hidden from the accessibility tree and excluded from sequential keyboard focus. Games cards and their ancestors MUST NOT be inert.

Each multi-item lane SHALL advance by one of its own cards per shared 6.1-second cycle: a five-second dwell followed by a 1.1-second `ease-in-out` movement. Both moving lanes SHALL share cycle phase and eased movement progress, but each SHALL use its own logical count, step count and full-loop duration. They SHALL loop continuously and independently without blank gaps or visible jumps. A pause reason scoped to Games SHALL pause both moving lanes together. A singleton lane SHALL remain static and unduplicated even if its sibling moves.

#### Scenario: Games renders at a supported wide viewport
- **WHEN** both Games lanes render at the supported wide layout
- **THEN** the hero row occupies approximately two thirds of the Games carousel presentation and the compact row approximately one third
- **AND** both rows retain landscape cards and existing responsive spacing

#### Scenario: Thirty-two games are delivered
- **WHEN** Games contains 32 distinct provider-selected entries
- **THEN** the hero lane contains entries 1 through 8 and the compact lane entries 9 through 32 in response order
- **AND** there are 32 canonical detail links with no cross-lane identity overlap
- **AND** any independent Playable overlap remains unchanged

#### Scenario: Small and near-capacity responses are partitioned
- **WHEN** the delivered Games count is respectively 2, 3, 4, 5, 8 or 31
- **THEN** hero/compact canonical counts are respectively 1/1, 1/2, 1/3, 2/3, 2/6 or 8/23
- **AND** the concatenated canonical lane identities exactly match the response without omissions or added entries

#### Scenario: Games advances automatically
- **WHEN** both Games lanes contain multiple entries and a dwell completes
- **THEN** both move at the same time and settle one own-card later with the same eased progress
- **AND** they move by their respective card widths rather than requiring equal pixel travel or matching game identities
- **AND** motion starts and ends gently without an instantaneous positional jump

#### Scenario: Games lanes wrap independently
- **WHEN** one Games lane reaches the end of its own sequence before the other
- **THEN** it continues from its own beginning seamlessly while its sibling advances normally
- **AND** their shared per-card cadence remains aligned without forcing equal full-loop durations
- **AND** no blank gap, missing game or duplicate accessible link appears at either wrap

#### Scenario: One Games lane is a singleton
- **WHEN** Games contains two entries
- **THEN** one static hero and one static compact canonical card render without loop copies or animation
- **AND** when Games contains three or four entries instead, the singleton hero stays static while the multi-item compact lane advances

#### Scenario: Games has one logical item
- **WHEN** the Games response contains exactly one entry
- **THEN** one static hero card renders with no animation, loop sentinel, Previous, Next, Play or Pause affordance
- **AND** the compact lane is absent

#### Scenario: Games has no logical items
- **WHEN** the Games response is empty
- **THEN** the complete Games section remains omitted, including both lanes and heading
- **AND** non-empty Playable remains unaffected

#### Scenario: Canonical link is unique in its assigned lane
- **WHEN** an entry is rendered in its assigned hero or compact lane alongside within-lane loop copies
- **THEN** exactly one accessible internal detail link for that entry exists in Games
- **AND** only its loop copies are hidden from accessibility navigation and skipped by Tab, while every visible copy still opens the game detail page

### Requirement: Carousel behavior is owned entirely by CSS
CSS SHALL own responsive hero and compact card geometry, the approximate Games row ratio, overflow containment, dwell and movement timing, continuous looping, seamless wrap, pause state, transition presentation and reduced-motion overrides. Carousel advancement SHALL use CSS keyframes with stepped timing over a track whose lane-local slide count is provided as a custom property. The shared carousel cadence, including Playable, SHALL use a five-second dwell followed by a 1.1-second `ease-in-out` movement; stepped sequence duration SHALL be the lane's logical count multiplied by the 6.1-second cycle. A singleton lane SHALL have no animation or loop copies. Derived-value types SHALL be inferred from typed inputs and computations without redundant annotations or comments explaining the derivation. All card markup SHALL be inline in the rendering loops, without card snippets. Svelte SHALL NOT add carousel state, timers, listeners, observers, selected-index synchronization, manual-scroll reconciliation, document-visibility tracking, dynamic ARIA status or scripted navigation controls; it MAY derive the two contiguous lossless lanes, render conditional sections and lanes, provide lane-local counts and singleton flags, and render loop copies with section-appropriate accessibility treatment: Games copies retain pointer activation with `aria-hidden` and anchor `tabindex="-1"`, while Playable copies remain inert. The primary production path MUST NOT depend on `::scroll-button()`, CSS anchor positioning, scroll snap events, container scroll-state queries or scroll-driven animations.

#### Scenario: Carousel advances without script
- **WHEN** a multi-item carousel is rendered and its dwell elapses
- **THEN** the next slide is settled by the CSS animation alone
- **AND** no timer, listener or observer participates in advancement

#### Scenario: Viewport changes
- **WHEN** home moves between supported desktop, tablet and mobile widths
- **THEN** CSS adapts hero and compact geometry within the shell without page-level inline overflow
- **AND** each moving lane retains the shared dwell/movement cadence and its own count-derived loop

#### Scenario: Experimental features are unavailable
- **WHEN** a current target lacks generated scroll buttons, anchor positioning, scroll snap events, scroll-state queries or scroll-driven animations
- **THEN** every multi-item carousel remains advancing, looping, pausable and linked through the baseline path
- **AND** singleton lanes remain static and linked

#### Scenario: Visual loop duplicate is present
- **WHEN** CSS looping uses duplicated slides for seamless wrap and focus runway
- **THEN** Games duplicate slides remain clickable, are hidden from the accessibility tree and have anchors excluded from sequential keyboard focus; Playable duplicate slides remain inert
- **AND** no real game is available solely through a duplicate
- **AND** loop travel is based on the lane's logical sequence rather than half of a rendered track with an additional tail

### Requirement: Auto-advancing carousels pause on hover and focus
Each rendered carousel with more than one logical item SHALL pause its CSS animation while a pointer hovers within its section or keyboard focus is within its section, and SHALL resume from the held position when the reason leaves. Pausing Games SHALL pause both moving lanes together so their per-card phases cannot drift apart despite independent loop lengths. Entering a static sibling lane SHALL retain the same Games pause scope. Playable SHALL retain its independent pause scope. Pause and resume SHALL be expressed only through CSS state such as `animation-play-state`; the implementation MUST NOT claim persistent Pause, Play controls, manual-stop persistence or document-hidden pausing that CSS cannot provide, and MUST NOT introduce script to provide them.

#### Scenario: Pointer hovers a running carousel
- **WHEN** pointer hover enters a running carousel section
- **THEN** its animation pauses at the current position
- **AND** it resumes from that position after hover leaves

#### Scenario: Focus enters a running carousel
- **WHEN** keyboard focus enters a canonical link in a running carousel section
- **THEN** its animation pauses without moving focus
- **AND** it resumes from the held animation position after focus leaves the section

#### Scenario: Games rows pause together
- **WHEN** hover or keyboard focus applies to either Games lane, including a static hero sibling
- **THEN** every moving Games lane pauses
- **AND** moving focus between lanes keeps them paused
- **AND** both resume with matched per-card phase once no pause reason remains

#### Scenario: Reduced motion is requested
- **WHEN** `prefers-reduced-motion: reduce` is active
- **THEN** carousel animation is removed and leading slides render statically
- **AND** non-essential card transitions are removed and no opt-in autoplay is reintroduced
- **AND** all canonical hero and compact links remain keyboard reachable and revealable

#### Scenario: Item count changes between responses
- **WHEN** a rendered collection's logical count changes across full home responses
- **THEN** the new response renders the correct lane split, slide counts, singleton states and animation timing
- **AND** no stale index, timer or binding survives from the previous response

### Requirement: Carousel links and focus remain accessible
Each delivered game SHALL expose exactly one semantic canonical detail link in each owning section using the server-resolved route slug with a meaningful accessible name and visible focus. Within Games, this link SHALL belong to the game's assigned hero or compact lane, and both lanes' canonical content SHALL remain in the accessibility tree and tab order. Only duplicated loop content SHALL be excluded. Canonical link order through hero then compact SHALL reproduce Games response order. A canonical link receiving keyboard-visible focus SHALL be fully revealed with its focus outline inside its own carousel viewport by CSS overflow containment and the loop-copy runway, without script involvement. The implementation SHALL NOT provide scripted Previous, Next, Play or Pause controls or dynamic status announcements, and canonical links SHALL carry their own accessible names. Card links in Playable, hero and compact lanes SHALL use `aria-label` with their game title or `Open game` when the title is absent or empty, without generated card-title IDs or card `aria-labelledby` references. Existing section-heading naming relationships SHALL remain intact.

#### Scenario: Canonical and duplicate content coexist
- **WHEN** a loop boundary renders duplicated content beside canonical content
- **THEN** only canonical links participate in keyboard and accessibility order
- **AND** each delivered game contributes exactly one accessible detail link in its owning section

#### Scenario: Keyboard focus reaches a canonical link
- **WHEN** a canonical hero or compact link receives keyboard-visible focus
- **THEN** the link shows visible focus and its section's moving tracks pause
- **AND** the focused link is revealed within its own carousel viewport through CSS containment and the loop-copy runway

#### Scenario: Focus enters after autoplay has passed the first game
- **WHEN** keyboard-visible focus reaches an earlier canonical link after multiple advances or a lane wrap
- **THEN** CSS temporarily neutralizes paused track displacement so native focus scrolling can reveal that link
- **AND** its focus outline is visible within the card
- **AND** leaving the section clears temporary focus scroll and restores compact centering with the held CSS animation position

#### Scenario: Focus reaches every compact game
- **WHEN** the user tabs through a 32-entry Games section or reverses direction with Shift+Tab
- **THEN** all eight hero and 24 compact canonical links are reachable in response order or its reverse
- **AND** sequential keyboard focus never enters a loop copy or trapped within the section
- **AND** the same complete route remains available with reduced motion

#### Scenario: Fallback metadata keeps a meaningful name
- **WHEN** a delivered game has no runtime display name
- **THEN** its canonical link retains a generic accessible name
- **AND** it remains keyboard reachable in server order in its assigned lane

### Requirement: Visible cards preserve local identity and metadata fallback
Every delivered game SHALL retain one canonical detail link in its owning section. Every entry SHALL link to D20 `/games/:slug` using the server-resolved non-null route slug, whether its Games lane is hero or compact. Local and provider-only entries SHALL share the same internal Inertia behavior; the client SHALL NOT choose an external BGG URL, derive a fallback slug or attach conditional navigation behavior. Client rendering keys SHALL use BGG identity rather than requiring a local ID; card accessible names SHALL use display titles directly without requiring heading IDs. Runtime metadata SHALL provide display fields when available. Missing or invalid per-item metadata within a successful response SHALL NOT remove a delivered card, alter lane membership or order, require a display name or create duplicate accessible links. Empty metadata SHALL retain the current linked fallback preview and generic accessible label. Compact canonical cards SHALL retain meaningful names and lifecycle treatment without relying on a hero representation of the same game.

#### Scenario: Playable card is activated
- **WHEN** a user activates a canonical Playable card
- **THEN** navigation targets that persisted game's D20 detail route by persisted slug

#### Scenario: Browse card is activated
- **WHEN** a user activates a canonical Games hero or compact card with a visible local association
- **THEN** navigation targets that persisted game's D20 detail route by persisted slug
- **AND** no carousel transition or catalog record is persisted

#### Scenario: A visible loop copy is activated
- **WHEN** a user clicks or taps a visible copied Games card in either the hero or compact lane
- **THEN** it opens the same D20 detail route through ordinary internal Inertia navigation as its canonical card
- **AND** the copied anchor has no inert ancestor and remains excluded from sequential keyboard navigation
- **AND** pointer focus preserves card position between pointer down and release so navigation is not lost to a focus-induced track shift
- **AND** the game retains one canonical accessible link in Games

#### Scenario: Metadata enrichment fails
- **WHEN** runtime metadata is unavailable for a delivered playable or browse record
- **THEN** the record remains in its server-selected collection, assigned lane and order
- **AND** its fallback card remains linked and keyboard accessible

#### Scenario: Compact metadata is shown on mobile
- **WHEN** a compact card has a long title or multiple categories at a narrow viewport
- **THEN** its title and category row do not overlap and visual truncation preserves the full accessible text
- **AND** a narrow in-development compact card may omit categories to make room for its badge, but retains its complete accessible game name and canonical link without requiring a hero copy

#### Scenario: Link uniqueness is inspected
- **WHEN** canonical slides and duplicated visual representations are present
- **THEN** each delivered game contributes exactly one accessible detail link in its owning section
- **AND** no loop copy contributes a duplicate accessible link

#### Scenario: Browse entry has no local association
- **WHEN** a delivered Games entry has a positive BGG ID, metadata, a decimal BGG route slug and null stage
- **THEN** its canonical card in either lane opens the internal numeric detail route through Inertia
- **AND** it has neutral lifecycle treatment without an in-development badge
- **AND** its decorative loop copies expose no additional accessible links

#### Scenario: Provider-only entry has empty display metadata
- **WHEN** a delivered entry has a numeric route slug and empty metadata
- **THEN** its fallback card retains a generic accessible name and its internal numeric detail link in its assigned lane
- **AND** the absence of a local ID or display name does not remove the card

### Requirement: Home tests cover application behavior and visual states
Home Storybook screenshot scenarios with semantic play assertions SHALL verify the disjoint Games split, exact canonical membership/order, content, internal local and numeric links in both lanes, nullable local stage, metadata fallback, and conditional sections and lanes. The split matrix SHALL include 0, 1, 2, 3, 4, 5, 8, 31 and 32 delivered Games. Presentation SHALL be verified through screenshot comparisons at named UI states and desktop/tablet/mobile viewports using the screenshotter defaults. Separate Home browser tests SHALL be limited to native keyboard focus/reveal, clipped-card pointer/Enter event delivery and reduced-motion presentation that the existing Storybook harness cannot faithfully exercise. Home SHALL NOT retain a redundant standalone component suite for Storybook-representable states. Tests SHALL NOT assert visual loop-copy counts, inert ancestry, exact tabIndex or aria-hidden values, per-copy action bindings or duplicated badge counts. Tests SHALL NOT query animation objects or CSS timing properties, manipulate playback or current time, or assert browser interpolation, pause/resume, duration, geometry or looping mechanics. Natural-playback browser review SHALL separately provide evidence of shared gentle movement and independent seamless wraps from actual changed-worktree markup and CSS before delivery is marked complete; static screenshots alone SHALL NOT count as motion evidence.

#### Scenario: Keyboard navigation is verified
- **WHEN** a browser test tabs through the home catalog
- **THEN** every canonical link in Playable and both Games lanes receives focus in server order and decorative duplicates never enter the tab order
- **AND** the test does not seek or inspect a browser animation

#### Scenario: Presentation is verified
- **WHEN** a test captures a home layout, focused card or reduced-motion state
- **THEN** it compares a screenshot using the screenshotter defaults
- **AND** it does not measure animation timing, playback state, geometry or intermediate motion frames
- **AND** affected singleton, two-item compact, long-title and fallback states remain reviewable at narrow widths

#### Scenario: One game appears in both sections
- **WHEN** the same BGG ID is delivered in Playable and Games
- **THEN** each section exposes one canonical link for that game
- **AND** both canonical links retain the game title as their accessible name and decorative copies add no accessible link

#### Scenario: Lane distributions are verified
- **WHEN** Storybook scenarios render the required Games count matrix
- **THEN** each lane has its specified canonical membership and concatenation reproduces the input exactly
- **AND** empty/singleton behavior remains covered and source review verifies that partitioning adds no requests
- **AND** the tests verify content and accessibility rather than CSS variables or implementation-specific timing

#### Scenario: Running motion evidence is recorded
- **WHEN** the implementation is reviewed in an identified actual worktree browser target with motion enabled
- **THEN** natural playback demonstrates 5-entry 2/3 unequal loops, a 3-entry 1/2 compact wrap, and a complete 32-entry 8/24 compact loop including intervening hero wraps
- **AND** the evidence records viewport, source provenance, smooth coordinated advances, no gaps or jumps, shared hover/focus pause and resumed cadence, and reduced-motion/focus behavior
- **AND** a CSS-only preview against unchanged master markup is not reported as verification of disjoint lanes

### Requirement: Compact carousel rows center their middle visible card
Each multi-item compact lane in Playable and the lower Games carousel SHALL align the middle visible card's center with its own viewport's center at every unfocused settled position. The initial middle card SHALL be the second entry in that lane's assigned sequence. Neighboring cards SHALL remain partially visible with equal clipping at the left and right viewport boundaries. CSS SHALL derive this composition from the existing responsive container and lane-local card geometry, retain it for unfocused reduced motion, and preserve continuous looping without blank gaps, including two-item lanes. Hero and singleton card geometry SHALL remain unchanged; singleton detection SHALL use lane count rather than the total Games response. Keyboard-visible focus SHALL temporarily clear compact alignment as needed to reveal canonical links and SHALL restore centered composition when focus leaves. Additional Games loop coverage SHALL remain pointer-activatable and hidden from the accessibility tree, with anchors excluded from sequential keyboard focus. Playable loop coverage SHALL retain its existing inert treatment.

#### Scenario: Both compact rows render
- **WHEN** Playable and the Games compact lane each contain multiple assigned entries at a supported desktop, tablet or mobile width
- **THEN** the initial middle visible card in each compact row is centered within that row's viewport
- **AND** neighboring cards are clipped symmetrically at its boundaries
- **AND** the Games hero retains its existing geometry

#### Scenario: Centered compact tracks advance and wrap
- **WHEN** a multi-item compact lane advances through a complete loop, including a two-item lane
- **THEN** each settled middle card is centered and no blank gap appears during advancement or wrap
- **AND** lane order, shared Games per-card cadence, independent loop counts and accessible link uniqueness are preserved

#### Scenario: Reduced motion keeps the centered composition
- **WHEN** reduced motion is requested and neither section contains keyboard focus
- **THEN** multi-item compact lanes show a centered static middle card with symmetrically clipped neighbors
- **AND** no animation is introduced

#### Scenario: Keyboard focus reveals the first canonical card
- **WHEN** focus enters a canonical link in a centered carousel section
- **THEN** the focused link and its focus outline are revealed through the existing CSS focus behavior
- **AND** leaving the section restores compact centering and the held animation position

#### Scenario: A lane contains one entry
- **WHEN** a Playable, hero or compact lane contains exactly one entry
- **THEN** its static card geometry remains unchanged and no loop copy is added
- **AND** it does not receive multi-item compact alignment solely because another lane contains games

### Requirement: Home carousel movement uses a soft shared cadence
Every animated home carousel row SHALL hold its settled slide stationary for 5 seconds, then move one slide over 1.1 seconds with CSS `ease-in-out` interpolation. The total step cycle SHALL be 6.1 seconds. The stepped loop displacement and interpolated movement SHALL use the same cycle so advancement and wrap remain continuous. Playable and both Games lanes SHALL use this cadence; moving Games lanes SHALL share per-card phase while retaining independent lane counts and complete-loop durations. Existing hover/focus pause, keyboard focus reveal, reduced-motion behavior, singleton presentation and compact centering SHALL remain intact. Games loop copies SHALL stay pointer-activatable and excluded from keyboard/accessibility navigation; Playable copies SHALL retain inert treatment.

#### Scenario: A running row advances
- **WHEN** a multi-item home row runs without a pause reason or reduced-motion preference
- **THEN** its card remains stationary for 5 seconds before the next 1.1-second movement
- **AND** the movement accelerates and decelerates through `ease-in-out` before settling one slide later
- **AND** the next cycle begins without a jump or blank gap

#### Scenario: Games rows move together
- **WHEN** the Games hero and compact lanes advance or resume after a shared pause
- **THEN** both moving lanes use the same 6.1-second cadence and transition progress while looping by their respective counts
- **AND** the settled compact card remains centered with equally clipped neighbors

#### Scenario: Motion is paused or disabled
- **WHEN** hover or focus pauses a section, reduced motion is active, or a lane contains a singleton
- **THEN** the existing pause, focus reveal, or static behavior is preserved
- **AND** the timing introduces no script timer, animation library, or new control
