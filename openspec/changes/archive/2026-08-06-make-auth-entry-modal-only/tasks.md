## 1. Server modal entry

- [x] 1.1 Add a safe one-time session-backed auth prompt to `D20Web.UserAuth` and expose it through the Inertia pipeline.
- [x] 1.2 Redirect protected, sudo, and invalid-token failures to the home modal host while preserving safe return destinations and user-facing messages.
- [x] 1.3 Remove the standalone registration and login GET routes and controller render actions while retaining their POST actions and magic-link confirmation.

## 2. Shared account dialog

- [x] 2.1 Extend `AuthDialog` and the shared header to consume server mode, reauthentication, return-path, email, and message state for guest and authenticated users.
- [x] 2.2 Remove the `pages/auth` slice and all page-resolution assumptions that registration or login has a standalone Inertia page.

## 3. Verification

- [x] 3.1 Update UserAuth, registration, session, settings, page, and route tests for one-time modal prompts, removed GET routes, retained POST actions, and safe returns.
- [x] 3.2 Update shared-header and layout tests for prompted Login and sudo dialog states using accessible browser queries.
- [x] 3.3 Format touched files and run targeted backend tests, frontend unit and browser tests, lint, and typecheck.
- [x] 3.4 Run broad repository checks and strict OpenSpec validation, then synchronize and archive the completed change.
