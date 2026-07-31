## REMOVED Requirements

### Requirement: Lobby handoff preserves Presence without controller transfer

**Reason**: The requirement describes the retired Presence-lease and `handoff_ready` model and conflicts with durable-membership workspace discovery and response-owned Lobby cleanup.

**Migration**: Use the `session-workspace-lifecycle` requirement "Lobby transition does not retain a Presence lease" as the authoritative Lobby transition contract.
