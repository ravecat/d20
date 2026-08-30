## 1. Persistence And Accounts Foundation

- [x] 1.1 Add a reversible migration that extends the `user_identities` provider constraint with `steam` while preserving existing ownership indexes.
- [x] 1.2 Keep the Steam migration limited to the `user_identities` provider and canonical SteamID constraints, without an OpenID nonce table or login-time persistence.
- [x] 1.3 Extend `D20.Accounts.UserIdentity` with canonical unsigned 64-bit SteamID validation and named database constraint mapping.
- [x] 1.4 Reuse issue #242's atomic user-and-identity registration for Steam with `email: nil` without adding provider-protocol operations to Accounts.
- [x] 1.5 Keep focused migration, schema, and Accounts tests for valid provider-only Steam identity storage, invalid SteamIDs, rollback, duplicate identity races, and database constraints.

## 2. Steam OpenID Protocol Boundary

- [x] 2.1 Re-check official Steam/OpenID sources and community `ueberauth_steam_strategy` 0.2.1; record that Valve provides no official Elixir adapter and accept the user-approved third-party package behavior.
- [x] 2.2 Add `ueberauth_steam_strategy ~> 0.2.1`, allowlist `Ueberauth.Strategy.Steam`, load normalized `STEAM_API_KEY`, and derive availability from both expected strategy and nonblank credential without an enable flag.
- [x] 2.3 Remove the D20-owned Steam strategy and Req OpenID client; delegate request, direct verification, and transient profile lookup to the community strategy through the same Ueberauth plug composition as Google and Discord.
- [x] 2.4 Treat the community strategy result as the complete Steam protocol boundary and validate only its provider tag plus canonical UID before account handling.
- [x] 2.5 Remove D20-owned assertion validation, response-nonce persistence, replay cleanup, callback mutation, and custom endpoint telemetry.
- [x] 2.6 Prove D20 does not duplicate the community strategy's remote OpenID verification or profile lookup calls.
- [x] 2.7 Keep focused community-adapter boundary tests for configuration, canonical result normalization, profile-data discard, failures, consumed intent, and no unmocked network traffic.

## 3. Steam Browser Authentication

- [x] 3.1 Add `D20Web.Auth.Steam` normalization plus ten-minute signed-session authenticate, reauthenticate, and link intents with safe return storage, user binding, terminal cleanup, and minimal failure classification.
- [x] 3.2 Keep exact Steam routes and align the controller with Google/Discord: availability guard, Ueberauth plug, auth/failure matching, D20 normalization, and no pre-adapter callback guard, callback scrubbing, or custom strategy-state cleanup.
- [x] 3.3 Implement returning login by exact `(:steam, steam_id)` identity through `D20Web.Auth`, preserving session rotation and safe local return.
- [x] 3.4 Implement account-bound Steam reauthentication that succeeds only for the current user's exact linked identity and never switches accounts.
- [x] 3.5 Normalize community adapter failure, missing credential, cancellation, consumed intent, malformed identity, and unexpected results into existing semantic prompts without logging provider data.
- [x] 3.6 Update focused adapter/controller tests for strategy-plus-key availability, community Ueberauth results, returning login, reauthentication, safe returns, rotation, unavailable callbacks, failures, and standard provider-shaped callback handling.

## 4. Provider-Only Steam Registration

- [x] 4.1 For an unknown verified SteamID, store only ten-minute integrity-protected session-bound completion state and redirect to the generic registration-completion page.
- [x] 4.2 Render null email and generic username submission/cancel metadata without exposing SteamID, assertion, provider proof, or browser-editable email.
- [x] 4.3 On valid username, atomically call issue #242's provider-neutral `register_user_with_identity/3` with `email: nil`, then clear completion and authenticate through the existing session boundary.
- [x] 4.4 Keep valid completion after missing, invalid, or duplicate username while creating no partial user or identity.
- [x] 4.5 Clear missing, expired, consumed, tampered, cancelled, or identity-conflicted completion state; roll back partial user creation and never authenticate the winner of a race.
- [x] 4.6 Add focused adapter, Accounts, and controller tests for nil-email creation, forged-email rejection, invalid and duplicate username retry, completion expiry/tampering/consumption/cancel, identity conflict and race rollback, remember-me, safe return, and session creation.
- [x] 4.7 Remove Steam-specific pending provider identity, registration-proof, email collection, email-delivery, and Magic Link completion code and tests; preserve later Add email through issue #242 only.

## 5. Explicit Linking And Shared Provider UI

- [x] 5.1 Add the sudo-protected `/users/settings/auth/steam` link route and same-user callback behavior, including idempotent same-identity linking and generic ownership conflicts.
- [x] 5.2 Add Steam availability and linked state to the existing ordered Account Settings provider collection without provider-specific top-level props or unlink action.
- [x] 5.3 Extend shared `auth.providers`, TypeScript declarations, Register controls, and Login controls with conditional Steam availability and full-document navigation.
- [x] 5.4 Update backend/frontend availability helpers for strategy plus `STEAM_API_KEY` and rerun Steam UI plus Apple, Discord, Google, email, password, Magic Link, linking, sudo, and nullable-email regressions.
- [x] 5.5 Revalidate current provider-only Register, Login, registration-completion, and Account Settings states with configured Chrome DevTools at supported mobile and desktop viewports, including keyboard focus, accessible names, failure guidance, and no browser warnings.
- [x] 5.6 Represent Steam in the shared Register/Login and Account Settings Storybook states, including available, linked, and unavailable scenarios, and use the generic null-email Auth Provider story for provider-only completion.

## 6. Configuration, Operations, And Data Safety

- [x] 6.1 Add concise `STEAM_API_KEY` guidance to `envs/.env.example` without restoring Steam protocol documentation in the general README.
- [x] 6.2 Keep general project README configuration concise by removing the Steam feature-flag row and provider protocol subsection.
- [x] 6.3 Restore standard `Plug.Telemetry`, retain only standard Phoenix parameter filtering, and prove shared props, form data, persisted records, and application diagnostics exclude the API key and transient profile/raw result data.
- [x] 6.4 Verify durable identities and all non-Steam methods remain safe across adapter success/failure, missing credential, and later credential restoration without Steam-specific login persistence.

## 7. Validation, Staging, And Completion

- [x] 7.1 Format touched Elixir and run focused dependency, adapter, Accounts, controller, route, runtime configuration, provider regression, and frontend tests after the provider-boundary simplification.
- [x] 7.2 Run `mix compile --warnings-as-errors`, `mix hex.audit`, `mix test`, and applicable frontend lint/type checks, resolving failures caused by this dependency reversal.
- [ ] 7.3 Re-run `just check` if practical; verify non-Steam authentication plus safe direct-route failure when the Steam strategy or API key is absent.
- [ ] 7.4 Deploy the Steam-capable candidate only to staging and record exact callback plus manual evidence for provider-only username completion, returning login, reauthentication, linking, cancellation, repeated or intent-less callback failure, identity conflicts, safe returns, session rotation, missing-credential behavior, and profile non-persistence.
- [ ] 7.5 Update GitHub issue #241 with current implementation and staging evidence, keep the Steam-capable release out of production until every acceptance criterion is verified, and reconcile affected persistent-identity parent criteria.
- [x] 7.6 Run strict validation for this change and all OpenSpec artifacts after implementation and evidence updates.
- [ ] 7.7 Archive only after staging, issue, production-readiness, and validation tasks are complete; include synchronized specs in the semantic completion commit and confirm the active change disappears.

### Current Automated Evidence

- Added Hex `ueberauth_steam_strategy` 0.2.1 and transitive Poison 4.0.1; the existing HTTPoison dependency was reused.
- Removed the D20-owned Steam Ueberauth strategy and Req protocol client. `SteamController` now uses the community strategy through the same Ueberauth callback composition as Google and Discord.
- The community strategy is the complete Steam protocol boundary. D20 no longer adds assertion/nonce persistence, callback scrubbing, route logging suppression, or custom endpoint telemetry; the callback now follows Google and Discord and normalizes only provider plus canonical UID.
- Focused Steam runtime, adapter, controller, Accounts, page/settings, Facebook, Google, Discord, Apple, direct-session, and auth regressions pass; the final rebased backend suite passes with 767 tests.
- Final merge-focused frontend suites pass with 65 unit and Chromium browser tests; frontend lint and typecheck pass with zero Svelte errors/warnings. Focused Steam Storybook coverage passes 42 desktop, tablet, and mobile visual tests.
- The latest `just check` passed format, OpenSpec lifecycle, frontend format, and lint before its concurrent full frontend run failed 12/153 tests through screenshot/browser timeouts, an existing 8-pixel `PlayerCountLabel` mismatch, and Firefox startup failure. The same 86 feature-scoped frontend tests pass together; task 5.6 now updates only the authentication and Account Settings story references, while no workspace or `PlayerCountLabel` reference is part of this change.
- `mix compile --warnings-as-errors`, formatting, `git diff --check`, strict change validation, and strict all-item OpenSpec validation pass for 76 items.
- `mix hex.audit` reports no retired or security-advisory packages after rebasing onto the current Bandit 1.12.5 target.
- GitHub issue #241 now records the approved community adapter, `STEAM_API_KEY`, transient profile behavior, operation-minimal trust boundary, and data-minimization behavior; staging criteria remain unchecked.
- Configured Chrome DevTools validation passes at 390x844 and 1440x900 for Register, Login, provider-only registration completion, provider-only Account Settings, and the live Steam Account Settings link, including keyboard reachability, accessible names, and no browser warnings.
- GitHub issue #241 records the operation-minimal adapter trust boundary and accepted replay-persistence tradeoff. Staging deployment, issue completion evidence, broad `just check`, and archive remain open.
- Issue #260 consolidated Registration Completion visual coverage to Magic Link and the generic null-email Auth Provider story. Steam-specific completion behavior remains covered by controller and frontend tests instead of a duplicate visual baseline.
- Original detached implementation remains recoverable from Git stash `steam-worktree-backup-before-rebase-to-master-2534454` until final review.
