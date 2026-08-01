## 1. Characterize Presence Admission

- [x] 1.1 Update focused SessionChannel and game-server tests to require automatic player admission after Presence online without a client `join` event.
- [x] 1.2 Cover duplicate online idempotency, rejected admission retaining spectator membership, and final-meta offline preserving game player state.

## 2. Implement Server-Owned Admission

- [x] 2.1 Make `D20.Game.Server` apply Session online membership and the internal game `join` command as one serialized transition with one final publication.
- [x] 2.2 Preserve online membership when game admission is rejected and keep offline handling status-only for default and custom servers.

## 3. Simplify the Client

- [x] 3.1 Remove `join()` from the shared Session store and remove Lobby `joinRequested`, phase gating, and explicit join dispatch while preserving subscription cleanup and canonical navigation.

## 4. Update Public Contracts

- [x] 4.1 Remove client-sent game `join` operations and messages from the Qwinto, Koala Rescue Club, and Next Station London AsyncAPI documents and describe Presence-driven admission.

## 5. Validate and Deliver

- [x] 5.1 Format touched files and run focused server, channel, custom-server, frontend lint, frontend typecheck, and AsyncAPI validation commands.
- [x] 5.2 Run relevant broader backend and frontend checks, validate OpenSpec strictly, and document any remaining coordinated iframe-client rollout risk.
