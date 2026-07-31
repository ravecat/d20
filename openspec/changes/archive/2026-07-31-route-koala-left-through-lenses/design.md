## Context

Koala command application now uses a private `lens/1` macro and Pathex operations for `join`, `start`, `roll`, and `submit`. A valid `left` command in `:setup` or `:ready` remains an exception: dispatch calls two command-specific helpers, the first deletes the actor with `Map.delete/2`, and the second updates phase with direct struct syntax. The transition intentionally accepts a missing actor as a no-op and does not pass through `Command.validate/1`.

## Goals / Non-Goals

**Goals:**

- Make the accepted pre-start `left` transition explicit in an `apply_command` reducer clause.
- Address the aggregate players field and refreshed phase with the existing Pathex lens vocabulary.
- Preserve missing-actor idempotency and derive readiness from the post-removal aggregate.
- Remove `leave_player/2` and `refresh_setup_phase/1` after their only call site is migrated.

**Non-Goals:**

- Change whether `left` is accepted, validated, or ignored in any phase.
- Change player-count rules, readiness calculation, projections, persistence, or protocol payloads.
- Migrate automatic turn resolution, scoring, or other direct aggregate updates outside command application.

## Decisions

### Route pre-start left directly to the reducer

The `:setup` and `:ready` dispatch clause will pass the original accepted command to `apply_command/2` and wrap the returned aggregate in the existing `{:ok, game}` shape. It will not introduce `Command.validate/1`: the command validator intentionally has no `left` clause, and adding validation would change an existing accepted command into `{:error, :unknown_command}`.

Alternative considered: mutate with lenses directly in `dispatch/2`. This would remove the helpers but keep `left` outside the reducer convention required for accepted state-changing commands.

### Require the aggregate field while treating the actor entry as optional

The reducer will call `Pathex.over!/3` on `lens(:players)`. Its function will call `Pathex.without/2` on `path(actor_id)` inside the players map. The bang operation keeps a missing aggregate field as a programmer defect, while `without/2` preserves the established no-op when the actor id is absent.

Alternative considered: call `Pathex.without/2` on the fully composed aggregate path. That is shorter, but it would also silently preserve the aggregate if the required `players` field path were invalid, weakening the existing internal-path failure contract. `Pathex.delete!/2` was rejected because it raises for an absent actor and breaks idempotency.

### Refresh phase from the mutated aggregate

After the roster mutation, the reducer will call `Rules.ready_to_start?/1` once, select `:ready` or `:setup`, and store the result with `Pathex.set!/3` through `lens(:phase)`. Keeping deletion and readiness refresh in one reducer clause makes their ordering visible and removes both command-specific helpers.

Alternative considered: combine the roster and phase paths with a multi-focus lens. The two mutations require different values and the phase depends on the post-removal aggregate, so sequential operations express the dependency directly.

## Risks / Trade-offs

- [Nested Pathex operations are more verbose than `Map.delete/2`] -> Keep the optional inner path local to the one reducer clause and retain the strict outer field lens.
- [A refactor could compute readiness from the pre-removal roster] -> Assign the updated aggregate before calling `Rules.ready_to_start?/1` and retain the existing multi-player and last-player leave tests.
- [Routing through a reducer could accidentally add command validation] -> Preserve the direct dispatch-to-reducer path and verify absent-actor and phase behavior through the public dispatch interface.

## Migration Plan

1. Route accepted pre-start `left` commands to the new reducer clause.
2. Mutate players and phase through Pathex and remove the unused helpers.
3. Run focused Koala aggregate tests, compiler warnings validation, and strict OpenSpec validation.

Rollback restores the prior helper pipeline and deletes the new reducer clause. No data, deployment, or protocol migration is required.

## Open Questions

None.
