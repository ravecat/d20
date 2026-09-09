## MODIFIED Requirements

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

## ADDED Requirements

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
