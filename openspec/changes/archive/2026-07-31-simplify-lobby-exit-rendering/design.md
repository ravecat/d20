## Context

The game detail page receives an optional `SessionDescriptor` through Inertia. A waiting descriptor selects Lobby, whose Session store observes realtime phase changes. When the phase becomes `in_progress` or `finished`, Lobby starts an Inertia visit to the canonical game URL, whose response supplies `session: null`.

Today the transition also hides Lobby locally in two places: Lobby sets a `visible` flag, and the page records a dismissed session id to derive a null `lobbySession`. This duplicates ownership and makes the page show Play before its server props represent the clean URL. The former Presence-lease reason for optimistic dismissal no longer exists.

## Goals / Non-Goals

**Goals:**

- Make the Inertia `session` prop the sole source for selecting Lobby versus the launch form.
- Keep the Lobby component and Session store mounted until the canonical navigation updates page props.
- Preserve canonical URL cleanup and normal Session store detachment.
- Align overlapping workspace specifications with the current no-lease lifecycle.

**Non-Goals:**

- Change session creation or start commands.
- Change the session descriptor, SessionChannel, WorkspaceChannel, or iframe contracts.
- Add navigation loading UI or retry behavior.
- Change workspace discovery or durable membership behavior.

## Decisions

### Render directly from the Inertia session prop

`game.svelte` will branch on `session` and key Lobby by `session.id`. It will not maintain a dismissed id or a derived copy of the prop.

Alternative considered: reassign `session` locally when Lobby starts. Rejected because it would mix a server-owned prop with client-owned mutation and would still be optimistic state.

### Let navigation completion own Lobby cleanup

Lobby will request the canonical game URL after observing `in_progress` or `finished`, but it will not hide itself or notify the parent. The returned `session: null` prop removes Lobby, and `onDestroy(controller.detach)` performs the existing cleanup.

Alternative considered: retain either the child `visible` flag or the parent dismissal marker. Rejected because both cause the UI to diverge from the current page props and are unnecessary now that workspace discovery derives from durable membership.

### Keep realtime and public contracts unchanged

The Session store remains responsible for phase observation, and `router.get` retains its current URL, scroll, and history options. No backend or protocol changes are required.

## Risks / Trade-offs

- [The activation panel can be empty while navigation is pending because the in-progress Session component renders no waiting controls] -> Accept the short transitional state so the launch form does not appear before the authoritative page response.
- [A failed navigation leaves the selected Lobby mounted] -> Preserve the URL and descriptor-consistent state; navigation retry behavior remains outside this focused simplification.
- [Removing obsolete specification text changes two capabilities] -> Limit the delta to Lobby transition ownership and preserve all workspace and session contracts.

## Migration Plan

Deploy the frontend and synchronized specifications together. No data migration is required. Rollback restores the removed local visibility state and the prior immediate Play transition.

## Open Questions

None.
