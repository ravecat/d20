## ADDED Requirements

### Requirement: Storybook interactions use deterministic component state

Storybook stories that own user interaction behavior SHALL express that behavior through a `play` function, SHALL remain isolated from live application transports, and SHALL run in the existing Chromium visual viewport projects before screenshot comparison.

#### Scenario: Workspace interaction stories use deterministic state

- **WHEN** a Workspace interaction story is prepared
- **THEN** a Storybook-only `phoenix-session` fixture supplies its complete deterministic session value through `set`
- **AND** shared transport states use a direct reactive status control
- **AND** initial, ready, and cleared state values remain inline and create fresh nested records
- **AND** the story returns `clear` as its cleanup
- **AND** the production Workspace state and runtime session implementation remain unchanged
- **AND** production component changes remain limited to compact-status presentation

#### Scenario: Workspace interaction behavior runs in the visual matrix

- **WHEN** the frontend test workflow runs
- **THEN** the Auto selection story verifies initial selection, Compact restoration, selection switching, keyboard activation, focus order, and fullscreen controls through accessible queries
- **AND** one ready connection-status story renders three sessions, including two Live sessions, one Finished session, and a long-identifier case
- **AND** dedicated Reconnecting and Failed stories present their shared Workspace transport overlays directly
- **AND** accessibility remains a cross-cutting addon check instead of receiving a dedicated Workspace story
- **AND** the existing desktop, tablet, and mobile Chromium Storybook projects execute each retained story before visual comparison

#### Scenario: Ready compact statuses share stable typography

- **WHEN** Live and Finished sessions render together in the ready connection-status story
- **THEN** each compact status dot and label group remains centered in its fixed-width control
- **AND** Live and Finished use the same reduced font size without state-specific typography overrides
- **AND** desktop, tablet, and mobile Chromium references preserve the reviewed presentation

#### Scenario: Superseded browser harness is removed

- **WHEN** the retained Storybook stories and lower-layer Workspace tests cover the former browser harness responsibilities
- **THEN** the manual Workspace browser harness is removed
- **AND** lower-layer model and presentation tests retain authoritative snapshot, Phoenix-session, SDK and frame lifecycle, subscription cleanup, and model-contract responsibilities
- **AND** Storybook does not duplicate those lower-layer implementation assertions as separate catalog stories
