## Why

Visitors can open local and BoardGameGeek-only game details but have no action when online play is unavailable. D20 needs an alternative action that records distinct account interest per game so operators can assess demand for online availability.

Tracking issue: [#275 - Players Can Request Online Availability for Games](https://github.com/ravecat/d20/issues/275), in [D20 Project 5](https://github.com/users/ravecat/projects/5).

The user authorized implementation after clarification of persistence, account deletion, and the mutually exclusive SessionForm and InterestForm components. Requests are durable, authenticated, and unique per account and BGG game. The independent delivery follows discovery issue #272 and does not absorb catalog administration #223, description layout #274, or richer availability explanations #127.

## What Changes

- Add game-detail Storybook stories grouped by `/games/:slug`, rendering the production page and layout for an existing Session, playable without a Session, unavailable without a Session, and saved interest. Use deterministic transport mocks and verify each state's visible activation action.
- Rename the game-detail Inertia prop `can_launch_game` / `canLaunchGame` to `playable`, retaining the complete existing server launch predicate and Session-creation authorization. Do not keep an alias or add a persisted playable field.
- Rename `LaunchForm` / `launch_form.svelte` to `SessionForm` / `session_form.svelte`, preserving its game-owned setup fields and `Play` action. Update imports and existing test/story consumers without a compatibility alias.
- Preserve the existing Session Lobby as the first activation state. Without a Session, playable games with a schema render `SessionForm`; non-playable resolved games render the new `InterestForm` / `interest_form.svelte` submission form, initially showing the single visible button `I want this game!` without game setup fields or `BasicForm`.
- Centralize configured stage visibility in `Games.visible?/1` and reuse it for detail access, interest eligibility, and launch eligibility. Keep SQL list filtering inside Games and preserve existing visibility/playability behavior.
- Treat interest as demand for online availability, including disabled games with engines and provider-only numeric routes. Neither the button nor `playable: false` claims that an engine is absent.
- Use `D20.Games.Interests` directly as the public interest context for request, membership, per-game counts, and grouped counts. Remove the redundant interest delegates from `D20.Games`. Controllers only translate HTTP input and context outcomes; Interests reuses Games for fresh route resolution, visibility, and launch policy.
- Submit interest using the original route alone. Remove the expected BGG ID payload, page prop, and mismatch check; the current server-resolved identity determines the request subject.
- Add authenticated interest submission and a persisted table with one unique request per account and resolved BGG ID. Count authoritative request rows instead of maintaining a separate mutable counter.
- Reuse the shared account dialog for guests; require explicit submission after authentication and record no guest request or automatic replay. Use the Svelte Inertia `Form` component directly for submission, pending state, and scoped server errors; use standard Inertia handling for network and unexpected HTTP failures.
- Treat submission for an already playable game as a silent no-op: redirect to its current detail without writing or showing an availability message. Persistence failures remain visible.
- Return the caller's saved-interest state with game details; show accessible pending, saved, and retryable error states with a per-game request count and five-point star before the button label. Confirm saved membership through the disabled `Requested` button without a separate success message below it.
- Preserve exact-local-slug-first resolution, provider error behavior, local visibility, and existing Session access. Resolve the interest subject from the local row or provider response rather than inferring it from a slug or creating a catalog row.

## Capabilities

### New Capabilities

- `game-interest`: Authenticated, idempotent demand submission through `InterestForm`, authoritative BGG identity, persistence and aggregate counts, requester state, and accessible feedback.

### Modified Capabilities

- `game-detail`: Rename the page launch prop, include requester interest state, and replace the explicit prohibition on an alternative provider-only action.
- `game-session-launch-policy`: Expose launch eligibility as `playable` and allow interest when launch is unavailable without changing server launch policy.
- `game-detail-activation-layout`: Select existing `Lobby`, `SessionForm`, or `InterestForm` within the current activation panel.

## Impact

- Backend: `D20.Games`, the public `D20.Games.Interests` context and its interest schema, `PageController`, a focused interest controller, and the Phoenix browser/Inertia route for `POST /games/:slug/interest`.
- Persistence: additive `game_interests` migration with an autogenerated interest-prefixed TypeID primary key, a user foreign key, positive BGG ID, timestamp, unique account/game pair, and an index supporting grouped counts. BGG metadata and local catalog records remain unchanged.
- Frontend: game-page props and activation rendering; rename `assets/js/pages/game/ui/launch_form.svelte` to `session_form.svelte` and add `interest_form.svelte` in that directory; update shared auth integration, imports, and affected tests, fixtures, and existing stories.
- Runtime/contracts: no Session, channel, iframe, module-token, or AsyncAPI changes. The existing launch endpoints and their error semantics remain authoritative.
- Rollback: roll application code back while retaining the additive interest table and its collected data. Dropping the table is a separate destructive data decision. No new dependency, dashboard, public ranking, vote cancellation, notification, or engine implementation is included.
