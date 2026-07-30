## ADDED Requirements

### Requirement: Mounted workspace game frames start independently of presentation

The workspace SHALL begin loading every authoritative game iframe when its session descriptor is mounted, regardless of whether the browser-local presentation is Compact, Theater, or fullscreen. The workspace MUST NOT defer the iframe's first navigation, SDK bootstrap, or iframe-owned realtime attachment until a player changes presentation mode.

#### Scenario: Workspace discovers a session in Compact mode

- **WHEN** a newly mounted workspace receives an authoritative descriptor for an active session and presents that session as Compact
- **THEN** the session iframe begins loading before the player expands or enters fullscreen
- **AND** the iframe can consume its issued module credentials while they are current

#### Scenario: Multiple sessions remain Compact

- **WHEN** an authoritative workspace snapshot contains multiple sessions and none is selected for Theater
- **THEN** each mounted iframe begins its own module runtime without waiting for presentation focus
- **AND** the shell does not create a duplicate per-game realtime controller

### Requirement: Compact hiding preserves a ready iframe runtime

The workspace SHALL keep Compact game content visually hidden, non-interactive, and unavailable to sequential keyboard and assistive-technology workflows while preserving the mounted iframe document and SDK bridge. Changing between Compact, Theater, and fullscreen MUST NOT be the event that first creates or replaces the game runtime.

#### Scenario: Player expands after an extended Compact interval

- **WHEN** a mounted game has remained Compact longer than the module credential acceptance window and the player expands it to Theater
- **THEN** the same iframe document and SDK bridge become visible and interactive
- **AND** the embedded client retains its established game session instead of attempting first-time bootstrap with the original credentials

#### Scenario: Player returns a loaded game to Compact

- **WHEN** a ready Theater or fullscreen game returns to Compact
- **THEN** the iframe remains mounted and its runtime may continue while its content is hidden and inert
- **AND** restoring the session exposes the same iframe document and SDK bridge
