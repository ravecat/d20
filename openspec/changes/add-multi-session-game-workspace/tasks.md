## 1. Preserve Existing Foundations

- [x] 1.1 Redirect successful session creation with status 303 to `/games/:slug?session=<id>` and validate the live session against the requested game slug.
- [x] 1.2 Keep `waiting_for_players` presentation and start controls in the game-page Lobby while clean game URLs remain launchable.
- [x] 1.3 Keep one persistent layout-owned workspace above replaceable Inertia page content.
- [x] 1.4 Keep Theater and Compact presentation, repeated game slugs, and stable iframe mounting across presentation changes.

## 2. Define the WorkspaceChannel Contract

- [x] 2.1 Add `priv/specs/workspace.yaml` as a separate AsyncAPI 3.0 contract for authenticated WorkspaceChannel join and server-pushed full snapshots.
- [x] 2.2 Define reusable schemas for workspace snapshots, session identity, module entry, and actor-bound module connection without duplicating game command or projection schemas.
- [x] 2.3 Document that only current-member `in_progress` sessions are reported and that waiting, finished, missing, and unconfigured sessions are excluded.
- [x] 2.4 Validate the AsyncAPI document with the repository's established contract tooling.

## 3. Add Actor-Scoped Server Discovery

- [x] 3.1 Add `D20Web.WorkspaceChannel` on the authenticated user socket and reject joins without a current actor scope.
- [x] 3.2 Configure user-socket request URI connect info and refactor module descriptor generation to accept controller or socket request context.
- [x] 3.3 Build one complete snapshot through the public `D20.Sessions` boundary, filtering to current-member `in_progress` sessions with configured modules.
- [x] 3.4 Return that snapshot in the successful join reply with fresh actor-bound module connection data.
- [x] 3.5 Subscribe each channel process to an internal actor-specific PubSub topic and push complete `snapshot` replacements directly to its client.
- [x] 3.6 Cover authentication, empty and multiple snapshots, repeated slugs, phase and membership filtering, module omission, actor-bound credentials, and payload isolation in focused channel tests.
- [x] 3.7 Capture trusted forwarded headers and normalize the browser-facing socket URI before workspace descriptor generation.
- [x] 3.8 Add regression coverage for internal HTTP socket upgrades producing public HTTPS iframe and WSS module URLs.

## 4. Publish Workspace Invalidations Centrally

- [x] 4.1 Extend the shared accepted-transition publication boundary to invalidate the union of old and new member ids when phase or membership can change workspace eligibility.
- [x] 4.2 Cover client-commanded, Presence-derived, and automatic transitions without coupling invalidation to command names such as `start`.
- [x] 4.3 Preserve the existing final-Presence-meta `left` behavior for ordinary transport closure while allowing the window `close` action to dispatch the session `left` event.
- [x] 4.4 Monitor every runtime pid represented by a WorkspaceChannel snapshot, update monitors during reconciliation, and immediately rebuild the snapshot on `:DOWN`.
- [x] 4.5 Add focused server tests for waiting-to-in-progress addition, in-progress-to-finished removal, Presence join, final-meta `left`, explicit global close, removed-member notification, automatic transition, normal and abnormal termination, and duplicate invalidation safety.

## 5. Make WorkspaceChannel the Sole Client Membership Source

- [x] 5.1 Add a typed WorkspaceChannel client with loading, ready, stale, failed, and reconnect states plus complete server snapshots.
- [x] 5.2 Reconcile the workspace by session id from each full snapshot, supporting repeated slugs and preserving local order and mode for retained ids.
- [x] 5.3 Render each workspace game window directly from its module descriptor and leave the existing SessionChannel to the module iframe.
- [x] 5.4 Refresh stored bootstrap descriptors without recreating retained iframe nodes or SDK bridges.
- [x] 5.5 Retain existing windows with a stale loading overlay during temporary WorkspaceChannel disconnects and apply the complete reconnect snapshot.
- [x] 5.6 Remove server membership, controller-transfer, focus-order bookkeeping, and iframe-mounted bookkeeping that become redundant in the workspace store.
- [x] 5.7 Cover additions, removals, refreshed credentials, duplicate snapshots, repeated slugs, stale reconnect, and iframe identity in focused frontend tests.

## 6. Replace Lobby Controller Adoption with Presence Overlap

- [x] 6.1 Mount the module iframe without creating a workspace-owned SessionController when WorkspaceChannel reports the newly in-progress session.
- [x] 6.2 Immediately clean the query URL and return the visible game page to its normal Play state when the Lobby session becomes `in_progress`.
- [x] 6.3 Retain the former Lobby SessionChannel invisibly as a Presence lease until WorkspaceChannel reports `handoff_ready`, then detach the Lobby store.
- [x] 6.4 Expose loading, stale, failed, or retry state on the workspace surface without keeping Lobby content visible.
- [x] 6.5 Remove the `adopt` controller-transfer path and navigation or dispatch reconciliation used only for that transfer.
- [x] 6.6 Add frontend and channel tests proving immediate Play presentation, server-observed Presence overlap, no final-meta `left` during transition, and no controller transfer.

## 7. Make Window Close the Only Membership Removal Control

- [x] 7.1 Keep one accessible close icon in each game-window overlay and make it send and await WorkspaceChannel `close`.
- [x] 7.2 On accepted close, let actor-scoped WorkspaceChannel snapshots remove the game and iframe in every browser tab without calling `D20.Sessions.stop/3`.
- [x] 7.3 Remove the separate Detach buttons, labels, callbacks, and user-facing terminology from the workspace dock, dialog API, and tests.
- [x] 7.4 Keep the game session store limited to Lobby `start` behavior and use its native `detach` only for lifecycle cleanup.
- [x] 7.5 Keep the window mounted with a retryable error when explicit close fails or times out.
- [x] 7.6 Add focused tests for close-button accessibility, global multi-tab removal, close failure, channel cleanup, and runtime-process survival.

## 8. Remove Superseded HTTP and Shared-Prop Paths

- [x] 8.1 Remove the Inertia Workspace plug and shared `sessions` prop from the browser pipeline.
- [x] 8.2 Remove the global Inertia shared-page-prop declaration and client bootstrap code used only for workspace sessions.
- [x] 8.3 Remove the workspace-session controller, endpoint, response types, and tests if no remaining caller uses them.
- [x] 8.4 Keep page controllers responsible only for page-specific Lobby selection and ensure page props never expose module tokens.
- [x] 8.5 Update router, controller, plug, and frontend tests to prove workspace discovery no longer depends on an Inertia response or separate HTTP bootstrap request.

## 9. Enforce Lifecycle and Presentation Semantics

- [x] 9.1 Remove a workspace window when an authoritative snapshot no longer contains it, including after finish, accepted Presence `left`, explicit global close, or monitored runtime termination.
- [x] 9.2 Verify a full page reload starts a new client workspace, uses only the new join snapshot, writes no browser storage, and does not promise restoration of previous windows.
- [x] 9.3 Verify temporary WorkspaceChannel loss retains stale windows and shows a loading overlay until the latest authoritative snapshot arrives.
- [x] 9.4 Keep Focus, Minimize, and Detach out of the session header and dock when the overlay already owns expansion and close.
- [x] 9.5 Verify keyboard access, visible focus, dialog focus behavior, Compact reachability, and unchanged iframe sandbox and SDK bootstrap behavior.

## 10. Validate the Integrated Change

- [x] 10.1 Format all touched Elixir, TypeScript, Svelte, and protocol files with repository-native commands.
- [x] 10.2 Run focused backend session, game-server, socket, channel, router, controller, and plug tests.
- [x] 10.3 Run focused frontend workspace, Lobby, layout, game-window, navigation, and accessibility tests.
- [x] 10.4 Run frontend type checks, lint, tests, and build checks.
- [x] 10.5 Run strict OpenSpec validation and the broad repository check.
- [x] 10.6 Perform browser validation for immediate Play transition with invisible Presence overlap, global multi-tab close, multi-session navigation, finish removal, stale socket recovery, monitored process termination, and full page reload.
