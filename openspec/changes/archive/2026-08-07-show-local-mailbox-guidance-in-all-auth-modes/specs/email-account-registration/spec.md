## MODIFIED Requirements

### Requirement: Local mailbox guidance matches development availability

The shared account flow SHALL expose the local mailbox link throughout every AuthDialog mode and state when `auth.local` is `true`. The server SHALL set `auth.local` to `true` only when development routes are enabled and `Swoosh.Adapters.Local` is the configured mail adapter and SHALL set it to `false` otherwise. AuthDialog SHALL read this value from the shared reactive Page props rather than requiring a caller-forwarded mailbox flag.

#### Scenario: Local development mailbox is available

- **WHEN** development routes are enabled and the Local mail adapter is configured
- **THEN** `auth.local` is `true`
- **AND** AuthDialog provides a link to `/dev/mailbox` in Register mode, Login mode, and their form-result states

#### Scenario: Local development mailbox is unavailable

- **WHEN** development routes are disabled or a non-Local mail adapter is configured
- **THEN** `auth.local` is `false`
- **AND** the account flow does not render a local mailbox link
